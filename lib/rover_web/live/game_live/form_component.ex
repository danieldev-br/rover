defmodule RoverWeb.GameLive.FormComponent do
  use RoverWeb, :live_component

  alias Rover.Rovers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage game records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="game-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:direction]} type="text" label="Direction" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Game</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{game: game} = assigns, socket) do
    changeset = Rovers.change_game(game)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"game" => game_params}, socket) do
    changeset =
      socket.assigns.game
      |> Rovers.change_game(game_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"game" => game_params}, socket) do
    save_game(socket, socket.assigns.action, game_params)
  end

  defp save_game(socket, :edit, game_params) do
    case Rovers.update_game(socket.assigns.game, game_params) do
      {:ok, game} ->
        notify_parent({:saved, game})

        {:noreply,
         socket
         |> put_flash(:info, "Game updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_game(socket, :new, game_params) do
    case Rovers.create_game(game_params) do
      {:ok, game} ->
        notify_parent({:saved, game})

        {:noreply,
         socket
         |> put_flash(:info, "Game created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
