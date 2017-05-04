defmodule LookupPhoenix.ImageController do
  use LookupPhoenix.Web, :controller
  alias LookupPhoenix.Image
  alias LookupPhoenix.ImageSearch
  alias LookupPhoenix.Repo

  def images_for(user, max) do
    Image
    |> ImageSearch.for_owner(user.id)
    |> ImageSearch.sort_by_created_at(:desc)
    |> ImageSearch.limit(max)
    |> Repo.all
  end
  
  def index(conn, _) do
    # images = Repo.all(Image)
    current_user = conn.assigns.current_user
    images = images_for(current_user, 20)
    render(conn, "index.html", images: images)
  end

  def edit(conn, %{"id" => id}) do
    image = Repo.get(Image, id)
    changeset = Image.changeset(image)
    render(conn, "edit.html",  action: image_path(conn, :update, image), image: image, changeset: changeset)
  end


  def update(conn, %{"id" => id, "image" => image_params}) do

   IO.puts "++++++++++++++++++++"
   IO.inspect(image_params)
   IO.puts "++++++++++++++++++++"

   user = conn.assigns.current_user
   image = Repo.get!(Image, id)
   changeset = Image.changeset2(image, image_params)
   {:ok, image} = Repo.update(changeset)
   render(conn, "show.html", image: image)
  end

  def show(conn, %{"id" => id}) do
    image = Repo.get!(Image, id)
    render(conn, "show.html", image: image)
  end

  def new(conn, _) do
     changeset = Image.changeset(%Image{})
     render(conn, "new.html", changeset: changeset)
   end

   def create(conn, %{"image" => image_params}) do
     IO.inspect image_params
     current_user = conn.assigns.current_user
     params = Map.merge(image_params, %{"owner_id" => current_user.id})
     changeset = Image.changeset(%Image{}, params)
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