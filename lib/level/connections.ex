defmodule Level.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to a space.

  ## Examples

      users(space, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%User{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def users(space, args, context \\ %{}) do
    Level.Connections.Users.get(space, args, context)
  end

  @doc """
  Fetch pending invitations for given a space.

  ## Examples

      invitations(space, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%Invitation{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def invitations(space, args, context \\ %{}) do
    Level.Connections.Invitations.get(space, args, context)
  end

  @doc """
  Fetch groups for given a space.

  ## Examples

      groups(space, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%Group{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def groups(space, args, context \\ %{}) do
    Level.Connections.Groups.get(space, args, context)
  end
end
