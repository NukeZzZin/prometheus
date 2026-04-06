admin_user = %Prometheus.Schemas.UserSchema{}
|> Prometheus.Schemas.UserSchema.create_user_changeset(%{
  username: "jcontin",
  display_name: "João Vitor Vieira Contin",
  email: "nukezzzin@gmail.com",
  password: "$uper$ecretPassw0rd"
})
|> Prometheus.Repository.insert!()

%Prometheus.Schemas.PostSchema{}
|> Prometheus.Schemas.PostSchema.create_post_changeset(%{
  author_id: admin_user.id,
  title: "Primeiro Post",
  content: "Esté é o primeiro post.",
})
|> Prometheus.Repository.insert!()

%Prometheus.Schemas.PostSchema{}
|> Prometheus.Schemas.PostSchema.create_post_changeset(%{
  author_id: admin_user.id,
  title: "Tutorial Post",
  content: """
  Caso queira testar o refresh-token, ctrl+shift+i e cole este comando no console:
  localStorage.setItem("prometheus:auth", JSON.stringify((buffer = JSON.parse(localStorage.getItem("prometheus:auth")), buffer.state.accessToken = "", buffer)));
  """,
})
|> Prometheus.Repository.insert!()
