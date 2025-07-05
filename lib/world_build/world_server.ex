defmodule WorldBuild.WorldServer do
  @moduledoc """
  GenServer that manages our game world state.
  Handles up to 100 players in the big house world.
  """
  use GenServer
  require Logger

  # Configuration
  @max_players 100
  @spawn_position %{x: 0.0, y: 0.0}  # Center of big house

  ## Client API (What other code calls)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  def join_player(username) do
    GenServer.call(__MODULE__, {:join_player, username})
  end

  def leave_player(player_id) do
    GenServer.call(__MODULE__, {:leave_player, player_id})
  end

  def get_world_state do
    GenServer.call(__MODULE__, :get_world_state)
  end

  def get_player_count do
    GenServer.call(__MODULE__, :get_player_count)
  end

  ## Server Implementation (What happens inside the GenServer)

  @impl true
  def init(:ok) do
    Logger.info("WorldServer starting...")

    initial_state = %{
      players: %{},           # Map of player_id => player_data
      max_players: @max_players,
      spawn_position: @spawn_position
    }

    {:ok, initial_state}
  end

  def update_position(player_id, position) do
    GenServer.cast(__MODULE__, {:update_position, player_id, position})
  end

  @impl true
  def handle_cast({:update_position, player_id, position}, state) do
    case Map.get(state.players, player_id) do
      nil ->
        # Player not found
        {:noreply, state}

      player ->
        # Update player position
        updated_player = %{player | position: position}
        new_players = Map.put(state.players, player_id, updated_player)
        new_state = %{state | players: new_players}

        Logger.info("Updated position for #{player.username}: (#{position.x}, #{position.y})")

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_call({:join_player, username}, _from, state) do
    cond do
      map_size(state.players) >= @max_players ->
        {:reply, {:error, :world_full}, state}

      true ->
        # Generate unique player ID
        player_id = generate_player_id()

        player = %{
          id: player_id,
          username: username,
          position: @spawn_position,
          joined_at: DateTime.utc_now()
        }

        new_players = Map.put(state.players, player_id, player)
        new_state = %{state | players: new_players}

        Logger.info("Player #{username} joined! Players online: #{map_size(new_players)}")

        {:reply, {:ok, player}, new_state}
    end
  end

  @impl true
  def handle_call({:leave_player, player_id}, _from, state) do
    case Map.get(state.players, player_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      player ->
        new_players = Map.delete(state.players, player_id)
        new_state = %{state | players: new_players}

        Logger.info("Player #{player.username} left! Players online: #{map_size(new_players)}")

        {:reply, {:ok, player}, new_state}
    end
  end

  @impl true
  def handle_call(:get_world_state, _from, state) do
    world_info = %{
      players: Map.values(state.players),
      player_count: map_size(state.players),
      max_players: state.max_players
    }

    {:reply, world_info, state}
  end

  @impl true
  def handle_call(:get_player_count, _from, state) do
    {:reply, map_size(state.players), state}
  end

  ## Private Functions

  defp generate_player_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end
end
