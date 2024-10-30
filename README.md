# Graph Coloring Project

This is a website built using **Elixir** language and **Phoenix Framework** (web framework) that implements **simulated annealing** and **genetic algorithms** to solve graph coloring, nqueens, and Travelling salesman problems. It is submitted as a requirement to pass the Introduction to AI Course 2023/2024 under the supervision of Prof. Emad Natsheh.

To start the website:

## Option 1: Running locally (elixir must be installed at local computer):

* Install and setup dependencies:
  
  ```bash
  mix setup
  ```
  
* Start Phoenix server with one of the following commands:
  
  ```bash
  mix phx.server
  ``` 

  ```bash
  iex -S mix phx.server
  ```
  
## Option 2: Running with Docker (docker must be installed at local computer):

* build the docker image using the following command:
  
  ```bash
  docker compose build
  ```
  
* run the container using the following command:

  ```bash
  docker compose up
  ```