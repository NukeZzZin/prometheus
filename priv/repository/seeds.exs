%Prometheus.Schemas.UserSchema{}
|> Prometheus.Schemas.UserSchema.create_user_changeset(%{
  id: 1,
  username: "jcontin",
  display_name: "João Vitor Vieira Contin",
  email: "nukezzzin@gmail.com",
  password: "$uper$ecretPassw0rd"
})
|> Prometheus.Repository.insert!()

%Prometheus.Schemas.PostSchema{}
|> Prometheus.Schemas.PostSchema.create_post_changeset(%{
  id: 1,
  author_id: 1,
  title: "Primeiro Post",
  content: "Esté é o primeiro post.",
})
|> Prometheus.Repository.insert!()
