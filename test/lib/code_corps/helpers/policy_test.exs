defmodule CodeCorps.Helpers.PolicyTest do
  use CodeCorps.ModelCase
  alias Ecto.Changeset
  alias CodeCorps.{
    Organization, User, Helpers.Policy,
    ProjectUser
  }

  def create_project_user_with_role(role) do
    user = insert(:user)
    project = insert(:project)
    insert(:project_user, project: project, user: user, role: role)
    {project, user}
  end

  describe "owned_by/2" do
    test "returns false when organization is not owned by user" do
      refute Policy.owned_by?(%Organization{owner_id: 1}, %User{id: 2})
    end

    test "returns false when invalid arguments are passed" do
      refute Policy.owned_by?(nil, 2)
    end

    test "returns false if a project is not owned by the user" do
      project = insert(:project)
      some_other_user = %User{id: 1}
      refute Policy.owned_by?(project, some_other_user)
    end

    test "returns true if a project is owned by the user" do
      {project, user} = create_project_user_with_role("owner")
      assert Policy.owned_by?(project, user)
    end

    test "returns false if a project is admined by the user" do
      {project, user} = create_project_user_with_role("admin")
      refute Policy.owned_by?(project, user)
    end

    test "returns false if a project is contributed by the user" do
      {project, user} = create_project_user_with_role("contributor")
      refute Policy.owned_by?(project, user)
    end

    test "returns false if a project user role is pending" do
      {project, user} = create_project_user_with_role("pending")
      refute Policy.owned_by?(project, user)
    end

    test "returns true when organization is owned by user" do
      assert Policy.owned_by?(%Organization{owner_id: 1}, %User{id: 1})
    end
  end

  describe "administered_by?/2" do

    test "returns false if given invalid arguments" do
      refute Policy.administered_by?(nil, 2)
    end

    test "returns true if the user is an admin" do
      {project, user} = create_project_user_with_role("admin")
      assert Policy.administered_by?(project, user)
    end

    test "returns true if the user is an owner" do
      {project, user} = create_project_user_with_role("admin")
      assert Policy.administered_by?(project, user)
    end

    test "returns false if the user is a contributor" do
      {project, user} = create_project_user_with_role("contributor")
      refute Policy.administered_by?(project, user)
    end

    test "returns false if the user is pending" do
      {project, user} = create_project_user_with_role("pending")
      refute Policy.administered_by?(project, user)
    end
  end

  describe "contributed_by?/2" do

    test "returns false if given invalid arguments" do
      refute Policy.contributed_by?(nil, 2)
    end

    test "returns true if the user is an admin" do
      {project, user} = create_project_user_with_role("admin")
      assert Policy.contributed_by?(project, user)
    end

    test "returns true if the user is an owner" do
      {project, user} = create_project_user_with_role("admin")
      assert Policy.contributed_by?(project, user)
    end

    test "returns true if the user is a contributor" do
      {project, user} = create_project_user_with_role("contributor")
      assert Policy.contributed_by?(project, user)
    end

    test "returns false if the user is pending" do
      {project, user} = create_project_user_with_role("pending")
      refute Policy.contributed_by?(project, user)
    end
  end

  describe "get_organization/1" do
    test "return organization if the organization_id is defined on the struct" do
      organization = insert(:organization)
      project = insert(:project, organization: organization)
      result = Policy.get_organization(project)
      assert result.id == organization.id
      assert result.name == organization.name
    end

    test "return organization if the organization_id is defined on the changeset" do
      organization = insert(:organization)
      changeset = %Changeset{changes: %{organization_id: organization.id}}
      result = Policy.get_organization(changeset)
      assert result.id == organization.id
      assert result.name == organization.name
    end

    test "return nil for structs with no organization_id" do
      assert Policy.get_organization(%{foo: "bar"}) == nil
    end

    test "return nil for any" do
      assert Policy.get_organization("foo") == nil
    end
  end


  describe "get_project/1" do
    test "return project if the project_id is defined on the struct" do
      project = insert(:project)
      project_category = insert(:project_category, project: project)
      result = Policy.get_project(project_category)
      assert result.id == project.id
      assert result.title == project.title
    end

    test "return project if the project_id is defined on the changeset" do
      project = insert(:project)
      changeset = %Changeset{changes: %{project_id: project.id}}
      result = Policy.get_project(changeset)
      assert result.id == project.id
      assert result.title == project.title
    end

    test "return nil for structs with no project_id" do
      assert Policy.get_project(%{foo: "bar"}) == nil
    end

    test "return nil for any" do
      assert Policy.get_project("foo") == nil
    end
  end

  describe "get_role/1" do
    test "should return a project user's role if it's defined" do
      assert Policy.get_role(%ProjectUser{role: "admin"}) == "admin"
    end

    test "should return a changeset's role if it's defined" do
      assert Policy.get_role(%Changeset{data: %{role: "contributor"}, types: %{role: :string}}) == "contributor"
    end

    test "should return nil if no role is defined on a project user" do
      assert Policy.get_role(%ProjectUser{}) == nil
    end

    test "should return nil if no role is defined on a changeset" do
      assert Policy.get_role(%Changeset{data: %{role: nil}, types: %{role: :string}}) == nil
    end

    test "should return nil if nil is passed in" do
      assert Policy.get_role(nil) == nil
    end
  end

  describe "get_task/1" do
    test "should return task of a TaskSkill" do
      task = insert(:task)
      task_skill = insert(:task_skill, task: task)
      result = Policy.get_task(task_skill)
      assert result.id == task.id
    end

    test "should return task of a UserTask" do
      task = insert(:task)
      user_task = insert(:user_task, task: task)
      result = Policy.get_task(user_task)
      assert result.id == task.id
    end

    test "should return task of a Changeset" do
      task = insert(:task)
      changeset = %Changeset{changes: %{task_id: task.id}}
      result = Policy.get_task(changeset)
      assert result.id == task.id
    end
  end

  describe "task_authored_by?/1" do
    test "returns true if the user is the author of the task" do
      user = insert(:user)
      task = insert(:task, user: user)
      assert Policy.task_authored_by?(task, user)
    end

    test "returns false if the user is not the author of the task" do
      user = insert(:user)
      other_user = insert(:user)
      task = insert(:task, user: user)
      refute Policy.task_authored_by?(task, other_user)
    end
  end

end
