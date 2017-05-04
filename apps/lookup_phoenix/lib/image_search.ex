defmodule LookupPhoenix.ImageSearch do
   use LookupPhoenix.Web, :model

   alias LookupPhoenix.Image
   alias LookupPhoenix.Utility

 #### SEARCH AND SORT -- COMPOSABLE QUERIES ####

    # https://blog.drewolson.org/composable-queries-ecto/

#    query = (Ectoing.User
#    |> select([u], u.surname)
#    |> distinct(true)
#    |> limit(3)
#    |> order_by([u], u.surname))

    def for_owner(query, owner_id) do
      from n in query,
        where: n.owner_id == ^owner_id
    end

    def limit(query, n) do
      from note in query,
        limit: ^n
    end

   def sort_by_created_at(query, direction \\ :asc) do
      if direction == :asc do
        from n in query,
           order_by: [asc: n.inserted_at]
      else
        from n in query,
           order_by: [desc: n.inserted_at]
      end
   end

    def title_search(query, term) do
      from n in query,
        where: ilike(n.title, ^"%#{term}%")
    end

#   def select_by_user_and_tag(query, user, tag) do
#       if Enum.member?(["all", "public"], tag) do
#         from n in query,
#           where: n.user_id == ^user.id
#       else
#         from n in query,
#           where: n.user_id == ^user.id and ^tag in n.tags
#       end
#    end
#    end
#
#    def select_public(query, public) do
#      if public == true do
#        from n in query,
#           where: n.public == ^true
#      else
#        query
#      end
#    end
#
#    def select_by_tag(query, tag_list, condition \\ true) do
#      if !is_list(tag_list) do
#        tag_list = [tag_list]  # THIS IS BAD CODE -- TRACK THINS DOWN AND FIX
#      end
#      if condition do
#        from n in query,
#          where: ilike(n.tag_string, ^"%#{hd(tag_list)}%")
#       else
#         query
#       end
#    end
#
#
#   def select_by_term(query, term, condition \\ true) do
#      if condition do
#        from n in query,
#          where: ilike(n.title, ^"%#{term}%") or ilike(n.tag_string, ^"%#{term}%")
#       else
#         query
#       end
#    end


    def most_recent(items, n) do
      Enum.slice(items, 0..(n-1))
    end


end