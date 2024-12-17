defmodule DemonPizza.Pizzerias do
  @moduledoc """
  The Pizzerias context.
  """

  import Ecto.Query, warn: false
  alias DemonPizza.Repo
  alias DemonPizza.Pizzerias.Pizzeria

  @doc """
  Returns the list of pizzerias.

  ## Examples

      iex> list_pizzerias()
      [%Pizzeria{}, ...]

  """

  def list_pizzerias(offset: offset, limit: limit) do
    Pizzeria
    |> select([p], %{
      pizzeria: p,
      position: fragment("row_number() OVER (ORDER BY ? DESC)", p.updated_at)
    })
    |> where([p], is_nil(p.status) or p.status == :opend)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  def list_all_pizzerias do
    Pizzeria
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  def list_pizzerias_by_city(city, state) do
    Pizzeria
    |> where([p], p.addr_city == ^city and p.addr_state == ^state)
    |> where([p], is_nil(p.status) or p.status == :opend)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  def save_osm_pizzerias_to_DemonPizza(location, type) do
    [lat, long] =
      case DemonPizza.GeoConversion.convert_coordinates(location.way) do
        {lat, long} ->
          ["#{lat}", "#{long}"]

        _ ->
          [nil, nil]
      end

    %{
      name: location.name,
      osm_id: "#{location.osm_id}",
      osm_type: type,
      addr_number: "#{location."addr:housenumber"}",
      addr_street: "#{location."addr:street"}",
      addr_unit: "#{location."addr:unit"}",
      addr_city: location."addr:city",
      addr_state: location."addr:state",
      addr_zip: "#{location."addr:postcode" || location."addr:zip"}",
      addr_lat: lat,
      addr_long: long,
      phone: "#{location.phone}",
      website: location."contact:website" || location.website
    }
    |> create_pizzeria()
  end

  # def fuzzy_search(query_string) do
  #   from(p in Pizzeria)
  #   |> where(
  #     [p],
  #     fragment("SIMILARITY(?, ?) > 0.9", p.name, ^query_string) or
  #     fragment("SIMILARITY(CONCAT(?, ' ', ?), ?) > 0.3", p.addr_number, p.addr_street, ^query_string)
  #   )
  #   |> order_by([p], fragment("GREATEST(SIMILARITY(?, ?), SIMILARITY(CONCAT(?, ' ', ?), ?)) DESC",
  #                        p.name, ^query_string,
  #                        p.addr_number, p.addr_street, ^query_string))
  #   |> Repo.all()
  # end
  def fuzzy_location_search(query) do
    normalized_query = String.downcase(query)

    city_weight = 1.5
    state_weight = 1.0

    Pizzeria
    |> where([p], fragment("similarity(?, ?) > 0.3", p.addr_city, ^normalized_query))
    |> or_where([p], fragment("similarity(?, ?) > 0.3", p.addr_state, ^normalized_query))
    |> select([p], %{addr_city: p.addr_city, addr_state: p.addr_state, id: p.id})
    |> group_by([p], [p.addr_city, p.addr_state, p.id])
    |> order_by(
      [p],
      fragment(
        """
        CASE
          WHEN lower(?) = ? THEN 1  -- Exact match is given top priority
          ELSE 2  -- Non-exact matches are given a lower priority
        END,
        (similarity(?, ?) * ?) + (similarity(?, ?) * ?) DESC
        """,
        p.addr_city,
        ^normalized_query,
        p.addr_city,
        ^normalized_query,
        ^city_weight,
        p.addr_state,
        ^normalized_query,
        ^state_weight
      )
    )
    |> Repo.all()
    |> Enum.uniq_by(fn %{addr_city: city, addr_state: state} -> {city, state} end)
    |> Enum.reject(fn %{addr_city: city, addr_state: state} -> city == nil or state == nil end)
  end

  def fuzzy_search(query_string, city, state, offset \\ 0, limit \\ 10) do
    normalized_query = normalize(query_string)

    from(p in Pizzeria)
    |> where(
      [p],
      fragment(
        "SIMILARITY(REGEXP_REPLACE(?, '[^a-zA-Z0-9 ]', '', 'g'), ?) > 0.2",
        p.name,
        ^normalized_query
      ) or
        fragment(
          "SIMILARITY(CONCAT(REGEXP_REPLACE(?, '[^a-zA-Z0-9 ]', '', 'g'), ' ', REGEXP_REPLACE(?, '[^a-zA-Z0-9 ]', '', 'g')), ?) > 0.3",
          p.addr_number,
          p.addr_street,
          ^normalized_query
        )
    )
    |> where([p], p.addr_city == ^city and p.addr_state == ^state)
    |> order_by(
      [p],
      fragment(
        "GREATEST(SIMILARITY(REGEXP_REPLACE(?, '[^a-zA-Z0-9 ]', '', 'g'), ?), SIMILARITY(CONCAT(REGEXP_REPLACE(?, '[^a-zA-Z0-9 ]', '', 'g'), ' ', REGEXP_REPLACE(?, '[^a-zA-Z0-9 ]', '', 'g')), ?)) DESC",
        p.name,
        ^normalized_query,
        p.addr_number,
        p.addr_street,
        ^normalized_query
      )
    )
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
    |> dbg()
  end

  defp normalize(query_string) do
    # Normalize the input query string
    String.replace(query_string, ~r/[^a-zA-Z0-9 ]/, "")
  end

  @doc """
  Gets a single pizzeria.

  Raises `Ecto.NoResultsError` if the Pizzeria does not exist.

  ## Examples

      iex> get_pizzeria!(123)
      %Pizzeria{}

      iex> get_pizzeria!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pizzeria!(id), do: Repo.get!(Pizzeria, id)

  @doc """
  Creates a pizzeria.

  ## Examples

      iex> create_pizzeria(%{field: value})
      {:ok, %Pizzeria{}}

      iex> create_pizzeria(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pizzeria(attrs \\ %{}) do
    %Pizzeria{}
    |> Pizzeria.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pizzeria.

  ## Examples

      iex> update_pizzeria(pizzeria, %{field: new_value})
      {:ok, %Pizzeria{}}

      iex> update_pizzeria(pizzeria, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pizzeria(%Pizzeria{} = pizzeria, attrs) do
    pizzeria
    |> Pizzeria.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pizzeria.

  ## Examples

      iex> delete_pizzeria(pizzeria)
      {:ok, %Pizzeria{}}

      iex> delete_pizzeria(pizzeria)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pizzeria(%Pizzeria{} = pizzeria) do
    Repo.delete(pizzeria)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pizzeria changes.

  ## Examples

      iex> change_pizzeria(pizzeria)
      %Ecto.Changeset{data: %Pizzeria{}}

  """
  def change_pizzeria(%Pizzeria{} = pizzeria, attrs \\ %{}) do
    Pizzeria.changeset(pizzeria, attrs)
  end

  def update_with_osm_id(
        %{
          "addr:housenumber": addr_number,
          "addr:street": addr_street,
          "addr:state": addr_state,
          "addr:city": addr_city,
          osm_id: osm_id,
          way: way
        },
        osm_type
      ) do
    {lat, lon} = DemonPizza.GeoConversion.convert_coordinates(way)

    if addr_number && addr_state && addr_city && addr_street do
      street = "%#{addr_street}%"

      query =
        from(r in DemonPizza.Pizzerias.Pizzeria,
          where:
            r.addr_number == ^addr_number and ilike(r.addr_street, ^street) and
              r.addr_state == ^addr_state and r.addr_city == ^addr_city,
          select: r
        )

      case DemonPizza.Repo.one(query) do
        nil ->
          {:error, "Record not found #{osm_id}"}

        record ->
          changeset =
            Ecto.Changeset.change(
              record,
              osm_id: "#{osm_id}",
              osm_type: osm_type,
              addr_lat: "#{lat}",
              addr_long: "#{lon}"
            )

          DemonPizza.Repo.update(changeset)
      end
    else
      {:error, "RECORD MISSING TOO MUCH DATA #{osm_id}"}
    end
  end
end

defmodule DemonPizza.GeoConversion do
  @radius 6_378_137

  def mercator_to_lat_lon({x, y}) do
    lon = x / @radius * 180 / :math.pi()
    lat = :math.atan(:math.sinh(y / @radius)) * 180 / :math.pi()
    {lat, lon}
  end

  def convert_coordinates(%Geo.Polygon{coordinates: [coordinates]}) do
    Enum.map(coordinates, &mercator_to_lat_lon/1)
    |> DemonPizza.GeoConversion.find_midpoint()
  end

  def convert_coordinates(%Geo.LineString{coordinates: coordinates}) do
    Enum.map(coordinates, &mercator_to_lat_lon/1)
    |> DemonPizza.GeoConversion.find_midpoint()
  end

  def convert_coordinates(%Geo.Point{coordinates: coordinates}) do
    mercator_to_lat_lon(coordinates)
  end

  def find_midpoint(coordinates) do
    count = length(coordinates)

    {sum_lat, sum_lon} =
      Enum.reduce(coordinates, {0, 0}, fn {lat, lon}, {sum_lat, sum_lon} ->
        {sum_lat + lat, sum_lon + lon}
      end)

    {sum_lat / count, sum_lon / count}
  end
end
