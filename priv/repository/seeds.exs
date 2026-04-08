Application.put_env(:prometheus, PrometheusEntry.Endpoint, server: false)
Application.ensure_all_started(:prometheus)

alias Prometheus.Repository
alias Prometheus.Schemas.{UserSchema, PostSchema}

admin_user = case Repository.get_by(UserSchema, username: "jcontin") do
  nil ->
    %UserSchema{}
    |> UserSchema.create_user_changeset(%{username: "jcontin", display_name: "João Contin", email: "nukezzzin@gmail.com", password: "$uper$ecretPassw0rd"})
    |> Repository.insert!()
  %UserSchema{} = record -> record
end

if is_nil(Repository.get_by(PostSchema, title: "Primeiro Post")) do
  %PostSchema{}
  |> PostSchema.create_post_changeset(%{author_id: admin_user.id, title: "Primeiro Post", content: "Esté é o primeiro post."})
  |> Repository.insert!()
end

if is_nil(Repository.get_by(PostSchema, title: "Tutorial Post")) do
  %PostSchema{}
  |> PostSchema.create_post_changeset(%{author_id: admin_user.id, title: "Tutorial Post", content: """
  Caso queira testar o refresh-token, ctrl+shift+i e cole este comando no console:
  localStorage.setItem("prometheus:auth", JSON.stringify((buffer = JSON.parse(localStorage.getItem("prometheus:auth")), buffer.state.accessToken = "", buffer)));
  window.location.reload();
  """})
  |> Repository.insert!()
end
