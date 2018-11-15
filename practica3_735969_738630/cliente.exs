# AUTOR: David Solanas Sanz y Diego Martínez Baselga
# NIAs: 738630    735969
# FICHERO: para_perfectos.exs
# FECHA: 21 de septiembre de 2018
# TIEMPO: 5 horas
# DESCRIPCION: codigo para el servidor / worker

defmodule Perfectos_cliente do
  def request(server_pid, tipo_server) do
    time1 = :os.system_time(:millisecond) 
    send(server_pid, {self(),2, tipo_server})
    receive do
      {:reply, listaPares} -> IO.inspect(listaPares, label: "La lista de pares es: ")
    end
    time = :os.system_time(:millisecond) - time1
    IO.puts(time)
  end
  
  
  defp lanza_request(server_pid, 1, tipo_server) do
  	#spawn(Perfectos_cliente, :request, [server_pid, tipo_server])
    request(server_pid, tipo_server)
  end
  
  defp lanza_request(server_pid, n, tipo_server) when n > 1 do
  	spawn(Perfectos_cliente, :request, [server_pid, tipo_server])
	lanza_request(server_pid, n - 1, tipo_server)
  end
  
  def genera_workload(server_pid, tipo_escenario) do
  	case tipo_escenario do
	  :uno -> 		lanza_request(server_pid, 1, :req)
	  :dos -> 		lanza_request(server_pid, System.schedulers, :perfectos)
	  :tres -> 		lanza_request(server_pid, System.schedulers*2, :perfectos)
	  :cuatro -> 	lanza_request(server_pid, System.schedulers*2, :perfectos_ht)
	  _ ->			IO.puts "Error!"
	end
  end
  
  def cliente(server_pid, tipo_escenario) do
	genera_workload(server_pid, tipo_escenario)
	:timer.sleep(2000)
	#cliente(server_pid, tipo_escenario)
  end
end
#Perfectos_cliente.cliente({:master, :"master@127.0.0.1"}, :uno)
