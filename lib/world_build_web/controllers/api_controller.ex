defmodule WorldBuildWeb.ApiController do
  use Phoenix.Controller, formats: [:json]

  def health(conn, _params) do
    json(conn, %{
      status: "ok",
      message: "World server is running!",
      timestamp: DateTime.utc_now()
    })
  end

  def join_world(conn, %{"username" => username}) do
    case WorldBuild.WorldServer.join_player(username) do
      {:ok, player} ->
        json(conn, %{
          status: "success",
          player: player,
          message: "Welcome to the world!"
        })

      {:error, :world_full} ->
        conn
        |> put_status(423)
        |> json(%{error: "World is full (100 players max)"})

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to join: #{reason}"})
    end
  end

  def world_state(conn, _params) do
    world_state = WorldBuild.WorldServer.get_world_state()
    json(conn, world_state)
  end

  def update_position(conn, %{"player_id" => player_id, "x" => x, "y" => y}) do
    # Cast is asynchronous, so we always return success
    WorldBuild.WorldServer.update_position(player_id, %{x: x, y: y})
    json(conn, %{status: "success"})
  end

end
