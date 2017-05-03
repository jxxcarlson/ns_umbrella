defmodule LookupPhoenix.ImageController do
  use LookupPhoenix.Web, :controller
  alias LookupPhoenix.Image
  alias LookupPhoenix.Repo

  
  def index(conn, _) do
    images = Repo.all(Image)
    render(conn, "index.html", images: images)
  end

  def new(conn, _) do
    changeset = Image.changeset(%Image{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"image" => image_params}) do
    IO.puts "------------"
    IO.inspect image_params
    IO.puts "------------"
    changeset = Image.changeset(%Image{owner_id: conn.assigns.current_user.id}, conn.assigns.current_user.id)
    IO.puts "------------"
    IO.inspect changeset
    IO.puts "------------"
    case Repo.insert(changeset) do
      {:ok, image} ->
        conn
        |> put_flash(:info, "Image was added")
        |> redirect(to: image_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> render("new.html", changeset: changeset)
    end
  end
  
end