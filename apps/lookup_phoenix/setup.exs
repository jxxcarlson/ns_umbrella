mix phoenix.server
alias LookupPhoenix.Repo
alias LookupPhoenix.Note
alias LookupPhoenix.Public
alias LookupPhoenix.User
alias LookupPhoenix.Tag


  <%= render LookupPhoenix.NoteView, "index.html", assigns %>
