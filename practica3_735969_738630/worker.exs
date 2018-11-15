# AUTORES: 
# NIAs: numeros de identificacion de los alumnos
# FICHERO: nombre del fichero
# FECHA: fecha de realizacion
# TIEMPO: tiempo en horas de codificacion
# DESCRIPCION: breve descripcion del contenido del fichero


defmodule Worker do

	def mandar_eleccion([]) do
	end 

	def mandar_eleccion([first|others]) do
		if first>self(), do: send(first, {:eleccion, self()})
		mandar_eleccion(others)
	end
		

	def mandar_soy_lider([], tipo, pid_master) do
      send(pid_master, {:tipo, -1, -1, self()})
	end

	def mandar_soy_lider([first|others], tipo, pid_master) do
		send(first, {:soy_lider})
		mandar_soy_lider(others, tipo, pid_master)
	end


	def empezar_eleccion(lista, tipo, pid_master) do
		mandar_eleccion(lista)
    IO.puts("He mandado eleccion")
		timeout=1000
		receive do
			{:ok}->empezar_worker(lista, tipo, pid_master)
					
			after
				timeout->mandar_soy_lider(lista, tipo, pid_master)
		end
	end



	def empezar_worker(lista, tipo, pid_master) do
		timeout=1000
		receive do
			{:eleccion, pid_origen}->
        IO.puts("recibido: eleccion")
				if (pid_origen<self()) do
					send(pid_origen, {:ok})
					empezar_eleccion(lista, tipo, pid_master)
				else
					empezar_worker(lista, tipo, pid_master)
				end
			{:soy_lider}->IO.puts("recibido: soy_lider")
                    empezar_worker(lista, tipo, pid_master)
				
			{:latido_lider}->IO.puts("recibido: latido_lider")
                    empezar_worker(lista, tipo, pid_master)
				
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
		:replySuma->workerSuma(lista, pid_master)
	  end
	end

  def init do 
    case :rand.uniform(100) do
      random when random > 80 -> :crash
      random when random > 50 -> :omission
      random when random > 25 -> :timing
      _ -> :no_fault
    end
  end  

  def workerSDP(lista, pid_master) do
    IO.puts("soy lider sdp")
    loopI(init(), :replySDP, lista, pid_master)
  end

   def workerDivisores(lista, pid_master) do
    IO.puts("soy lider workerDivisores")
    loopI(init(), :replyDiv, lista, pid_master)
  end

   def workerSuma(lista, pid_master) do
    IO.puts("soy lider suma")
    loopI(init(), :replySum, lista, pid_master)
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
      :crash -> if :rand.uniform(100) > 75, do: 10000, else: 0
      :timing -> :rand.uniform(100)*10 #00
      _ ->  0
    end
    IO.puts(delay)
    Process.sleep(delay)
	enviar_latido(lista)
	timeout=500
    case which_worker do
      :replySDP ->   receive do
                       {:reqWorkerSDP, {m_pid,m, idOp}} ->
                                if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault)) do 
                                  IO.puts("Envio respuesta")
                                  send(m_pid, {:replySDP, suma_divisores_propios(m), idOp, self()})
                              end
					  after
						timeout->nuevo_worker(which_worker,lista, :false, pid_master)
                      end

      :replyDiv ->   receive do
                       {:reqWorkerDiv, {m_pid,m, idOp}} -> 
                                if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault)) do 
                                  IO.puts("Envio respuesta")
                                  send(m_pid, {:replyDiv, divisores_propios(m), idOp, self()})
                              end
					  after
						timeout->nuevo_worker(which_worker,lista, :false, pid_master)
                      end

      :replySum ->   receive do
                       {:reqWorkerSuma, {m_pid,m, idOp}} ->
                                if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault)) do 
                                  IO.puts("Envio respuesta")
                                  send(m_pid, {:replySuma, suma(m), idOp, self()})
                              end
					  after
						timeout->nuevo_worker(which_worker,lista, :false, pid_master)
                      end
    end
  

    loopI(worker_type, which_worker,lista, pid_master)
  end

  defp divisores_propios(a,a) do
    []
  end

  defp divisores_propios(a,b) when a != b do
    if rem(a,b) == 0, do: [b] ++ divisores_propios(a,b+1), else: divisores_propios(a,b+1)
  end

def divisores_propios(a) when a == 1 do
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

  def suma_divisores_propios(n) when n == 1 do
    0
  end

end
