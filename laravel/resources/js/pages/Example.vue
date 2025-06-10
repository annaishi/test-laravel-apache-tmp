<template>
    <div class="container">
      <h1>User Management</h1>
  
      <!-- Authentication Section -->
      <div>
        <h2>Authentication Section</h2>
        <div v-if="!isAuthenticated">
          <input v-model="loginForm.email" type="email" placeholder="Email" />
          <input
            v-model="loginForm.password"
            type="password"
            placeholder="Password"
          />
          <button @click="login">Login</button>
        </div>
        <div v-else>
          <p>Logged in as: {{ user?.name }}</p>
          <button @click="logout">Logout</button>
        </div>
      </div>
  
      <!-- User Info Section -->
      <div>
        <h2>My Info Section</h2>
        <p>Name: {{ user?.name }}</p>
        <p>Email: {{ user?.email }}</p>
      </div>
  
      <!-- User List Section -->
      <div>
        <h2>User List Section</h2>
        <ul>
          <li v-for="user in users" :key="user.id">
            {{ user.name }} ---
            <button @click="deleteUser(user.id)">Delete</button>
          </li>
        </ul>
      </div>
  
      <!-- User Details Section -->
      <div>
        <h2>User Details Section(ID=1)</h2>
        <p>ID: {{ selectedUser.id }}</p>
        <p>Name: {{ selectedUser?.name }}</p>
        <p>Email: {{ selectedUser?.email }}</p>
      </div>
  
      <!-- User Creation Section -->
      <div>
        <h2>Create User Section</h2>
        <input v-model="newUser.name" type="text" placeholder="Name" />
        <input v-model="newUser.email" type="email" placeholder="Email" />
        <input
          v-model="newUser.password"
          type="password"
          placeholder="Password"
        />
        <button @click="createUser">Create</button>
      </div>
  
      <!-- User Edit Section -->
      <div>
        <h2>Edit User Section(ID=1)</h2>
        <input :value="editingUser.id" type="text" placeholder="ID" disabled />
        <input v-model="editingUser.name" type="text" placeholder="Name" />
        <input v-model="editingUser.email" type="email" placeholder="Email" />
        <button @click="updateUser">Update</button>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref } from "vue";
  import axios from "axios";
  
  // State variables
  const isAuthenticated = ref(false);
  const user = ref(null);
  const users = ref([]);
  
  // Forms
  const loginForm = ref({
    email: "",
    password: "",
  });
  
  const newUser = ref({
    name: "",
    email: "",
    password: "",
  });
  const selectedUser = ref({
    id: 1,
    name: "",
    email: "",
  });
  const editingUser = ref({
    id: 1,
    name: "",
    email: "",
  });
  
  // Methods
  const login = async () => {
    try {
      const response = await axios.post("/resources/login", loginForm.value);
      fetchMyInfo();
      loginForm.value = {
        email: "",
        password: "",
      };
    } catch (error) {
      console.error("Login failed:", error);
    }
  };
  
  const logout = async () => {
    try {
      await axios.post("/resources/logout");
      user.value = null;
      isAuthenticated.value = false;
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };
  
  const getMe = async () => {
    try {
      const response = await axios.get("/resources/me");
      user.value = response.data.user;
      isAuthenticated.value = true;
    } catch (error) {
      isAuthenticated.value = false;
      user.value = null;
      console.error("Failed to fetch user info:", error);
    }
  };
  
  const getUsers = async () => {
    try {
      const response = await axios.get("/resources/users");
      users.value = response.data.users;
    } catch (error) {
      console.error("Failed to fetch users:", error);
    }
  };
  
  const getUser = async (id) => {
    try {
      const response = await axios.get(`/resources/users/${id}`);
      selectedUser.value = response.data.user;
      editingUser.value = { ...selectedUser.value };
    } catch (error) {
      console.error("Failed to fetch user details:", error);
    }
  };
  
  const createUser = async () => {
    try {
      const response = await axios.post("/resources/users", newUser.value);
      getUsers();
      getUser(selectedUser.value.id);
      getMe();
      newUser.value = {
        name: "",
        email: "",
        password: "",
      };
    } catch (error) {
      console.error("Failed to create user:", error);
    }
  };
  
  const updateUser = async () => {
    try {
      const response = await axios.put(
        `/resources/users/${editingUser.value.id}`,
        editingUser.value
      );
      getUsers();
      getUser(selectedUser.value.id);
      getMe();
    } catch (error) {
      console.error("Failed to save user:", error);
    }
  };
  
  const deleteUser = async (id) => {
    try {
      if (user.value?.id === id) {
        alert("You cannot delete yourself.");
        return;
      }
      await axios.delete(`/resources/users/${id}`);
      getUsers();
      getUser(selectedUser.value.id);
      getMe();
    } catch (error) {
      console.error("Failed to delete user:", error);
    }
  };
  
  // Fetch initial data
  const fetchMyInfo = async () => {
    await getMe();
    await getUsers();
    await getUser(selectedUser.value.id);
  };
  fetchMyInfo();
  </script>
  
  <style scoped>
  .container {
    overflow-y: auto;
  }
  
  /* General styles */
  div {
    margin-bottom: 20px;
  }
  
  h1,
  h2 {
    color: #333;
  }
  
  input {
    display: block;
    margin: 10px 0;
    padding: 8px;
    width: 100%;
    max-width: 300px;
    border: 1px solid #ccc;
    border-radius: 4px;
  }
  
  button {
    padding: 10px 15px;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }
  
  button:hover {
    background-color: #0056b3;
  }
  
  /* User list styles */
  ul {
    list-style-type: none;
    padding: 0;
  }
  
  li {
    margin: 5px 0;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  
  li button {
    margin-left: 10px;
  }
  
  /* User details section */
  p {
    margin: 5px 0;
  }
  </style>