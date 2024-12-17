defmodule DemonPizza.Pizzerias.Pizzeria do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pizzerias" do
    field :name, :string
    field :status, Ecto.Enum, values: [:opend, :closed, :flagged]
    field :description, :string
    field :services, :map
    field :osm_id, :string
    field :osm_type, :string
    field :addr_number, :string
    field :addr_street, :string
    field :addr_unit, :string
    field :addr_city, :string
    field :addr_county, :string
    field :addr_state, :string
    field :addr_zip, :string
    field :addr_lat, :string
    field :addr_long, :string
    field :largest_cheeze_price, :integer
    field :largest_cheeze_size, :integer
    field :menu, :map
    field :phone, :string
    field :email, :string
    field :website, :string
    field :diets, :map
    field :operating_hours, :map
    field :food_inspector_ratings, :map
    field :verified_at, :map
    field :claimed_by_user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pizzeria, attrs) do
    pizzeria
    |> cast(attrs, [
      :name,
      :osm_id,
      :osm_type,
      :addr_number,
      :addr_street,
      :addr_unit,
      :addr_city,
      :addr_county,
      :addr_state,
      :addr_zip,
      :addr_lat,
      :addr_long,
      :description,
      :largest_cheeze_price,
      :largest_cheeze_size,
      :menu,
      :phone,
      :email,
      :website,
      :services,
      :diets,
      :operating_hours,
      :food_inspector_ratings,
      :verified_at,
      :status
    ])
    |> validate_required([
      :name
    ])
    |> unique_constraint(:osm_id, name: :pizzerias_osm_id_osm_type_index)
  end
end
