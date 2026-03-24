Prometheus.Repository.insert!(%Prometheus.Schemas.UserSchema{}, %{
  id: 1,
  user_flags: 0b1,
  username: "jcontin",
  display_name: "João Vitor Vieira Contin",
  email: "nukezzzin@gmail.com",
  password: "$uper$ecretPassw0rd",
})

Prometheus.Repository.insert!(%Prometheus.Schemas.PostSchema{}, %{
  id: 1,
  user_id: 1,
  title: "Primeiro Post",
  content: "Esté é o primeiro post.",
})
