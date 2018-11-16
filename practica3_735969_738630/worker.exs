# AUTORES: David Solanas Sanz y Diego Martínez Baselga
# NIAs: 738630 y 735969
# FICHERO: worker.exs
# FECHA: 15 noviembre 2018
# TIEMPO: 25 horas
# DESCRIPCION: código de los procesos workers


defmodule Worker do

	def mandar_eleccion([]) do
	end 

	def mandar_eleccion([first|others]) do
		if first>self(), do: send(first, {:eleccion, self()})
		mandar_eleccion(others)
	end
		

	def mandar_soy_lider([], tipo, pid_master) do
      send(pid_master, {tipo, -1, -1, self()})
	end

	def mandar_soy_lider([first|others], tipo, pid_master) do
		send(first, {:soy_lider})
		mandar_soy_lider(others, tipo, pid_master)
	end


	def empezar_eleccion(lista, tipo, pid_master) do
		mandar_eleccion(lista)
		timeout=50
		receive do
			{:ok}->empezar_worker(lista, tipo, pid_master)
					
			after
				timeout->mandar_soy_lider(lista, tipo, pid_master)
		end
	end



	def empezar_worker(lista, tipo, pid_master) do
    timeout=case tipo do
      :replySDP -> 100
      :replyDiv -> 150
      :replySum -> 250
    end
		receive do
			{:eleccion, pid_origen}->
				if (pid_origen<self()) do
					send(pid_origen, {:ok})
					empezar_eleccion(lista, tipo, pid_master)
				else
					empezar_worker(lista, tipo, pid_master)
				end
			{:soy_lider}-> empezar_worker(lista, tipo, pid_master)
				
			{:latido_lider}-> empezar_worker(lista, tipo, pid_master)
				
			after
				timeout->empezar_eleccion(lista, tipo, pid_master)
		end
	end
					                                                                                        
  def nuevo_worker(tipo, lista, lanzar, pid_master) do
	 case lanzar do
		:false->empezar_worker(lista, tipo, pid_master)
		:true->empezar_eleccion(lista, tipo, pid_master)
	 end
	 case tipo do
		:replySDP->workerSDP(lista, pid_master)
		:replyDiv->workerDivisores(lista, pid_master)
		:replySum->workerSuma(lista, pid_master)
	  end
	end

  def init(tipo) do 
    case tipo do
      :replySDP->case :rand.uniform(100) do
                    random when random > 95 -> :crash
                    random when random > 92 -> :timing
                    random when random > 75 -> :omission
                    _ -> :no_fault
                  end
      :replyDiv->case :rand.uniform(100) do
                    random when random > 98 -> :crash
                    random when random > 97 -> :timing
                    random when random > 75 -> :omission
                    _ -> :no_fault
                  end
      :replySum->case :rand.uniform(100) do
                    random when random > 98 -> :crash
                    random when random > 97 -> :timing
                    random when random > 75 -> :omission
                    _ -> :no_fault
                 end
    end
  end  

  def workerSDP(lista, pid_master) do
    IO.puts("soy lider sdp")
    loopI(init(:replySDP), :replySDP, lista, pid_master)
  end

   def workerDivisores(lista, pid_master) do
    IO.puts("soy lider workerDivisores")
    loopI(init(:replyDiv), :replyDiv, lista, pid_master)
  end

   def workerSuma(lista, pid_master) do
    IO.puts("soy lider suma")
    loopI(init(:replySum), :replySum, lista, pid_master)
  end

	defp enviar_latido([]) do  
	end

	defp enviar_latido([first|others]) do
		send(first, {:latido_lider})
		enviar_latido(others)
	end
		

  defp loopI(worker_type, which_worker, lista, pid_master) do
    IO.puts(worker_type)
    delay = case worker_type do
      :crash -> if :rand.uniform(100) > 98, do: :infinity, else: 0
      :timing -> :rand.uniform(200)*100 
      _ ->  0
    end
    IO.puts(delay)
    Process.sleep(delay)
	enviar_latido(lista)
	timeout=50
    case which_worker do
      :replySDP ->  receive do
                       {:reqWorkerSDP, {m_pid,m, idOp}} ->
                                if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault)) do
                                IO.inspect(idOp, label: "Envio operacion: ") 
                                  send(m_pid, {:replySDP, suma_divisores_propios(m), idOp, self()})
                              end
                              workerSDP(lista, pid_master)
					  after
						timeout->nuevo_worker(which_worker,lista, :false, pid_master)
                      end

      :replyDiv ->   timeout=2*timeout
            receive do
                       {:reqWorkerDiv, {m_pid,m, idOp}} -> 
                                if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault)) do 
                                   IO.inspect(idOp, label: "Envio operacion: ") 
                                  send(m_pid, {:replyDiv, divisores_propios(m), idOp, self()})
                              end
                              workerDivisores(lista, pid_master)
					  after
						timeout->nuevo_worker(which_worker,lista, :false, pid_master)
                      end

      :replySum -> timeout=4*timeout  
              receive do
                       {:reqWorkerSuma, {m_pid,m, idOp}} ->
                                if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault)) do
                                 IO.inspect(idOp, label: "Envio operacion: ")  
                                  send(m_pid, {:replySum, suma(m), idOp, self()})
                              end
                              workerSuma(lista, pid_master)
					  after
						timeout->nuevo_worker(which_worker,lista, :false, pid_master)
                      end
    end
  
  end

  defp divisores_propios(a,a) do
    []
  end

  defp divisores_propios(a,b) when a != b do
    if rem(a,b) == 0, do: [b] ++ divisores_propios(a,b+1), else: divisores_propios(a,b+1)
  end

def divisores_propios(a) when a == 1 or a == 0 do
    []
  end

  def divisores_propios(a) when a > 1 do
    divisores_propios(a,1)
  end

  def suma([]) do
    0
  end

  def suma([head|tail]) do
    head + suma(tail)
  end

  defp suma_divisores_propios(_, 1) do
    1
  end
  
  defp suma_divisores_propios(n, i) when i > 1 do
    if rem(n, i)==0, do: i + suma_divisores_propios(n, i - 1), else: suma_divisores_propios(n, i - 1)
  end
  
  def suma_divisores_propios(n) when n > 1 do
    suma_divisores_propios(n, n - 1)
  end

  def suma_divisores_propios(n) when n == 1 or n == 0 do
    0
  end

end
