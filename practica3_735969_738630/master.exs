# AUTORES: 
# NIAs: numeros de identificacion de los alumnos
# FICHERO: nombre del fichero
# FECHA: fecha de realizacion
# TIEMPO: tiempo en horas de codificacion
# DESCRIPCION: breve descripcion del contenido del fichero

defmodule Master do


def master(worker_div, worker_suma, worker_sdp) do
	receive do
		{c_pid, num1, :req} -> masterAux(worker_div, worker_suma, worker_sdp, num1, [], c_pid)
	end
	master(worker_div, worker_suma, worker_sdp)
end


defp masterAux(worker_div, worker_suma, worker_sdp, num1, listaPares, c_pid) when num1 > 20000 do
	send(c_pid, {:reply, listaPares})
end


#Calcula los pares de numeros amigos desde num1 hasta n
defp masterAux(worker_div, worker_suma, worker_sdp, num1, listaPares, c_pid) do
	IO.puts(num1)
	sumaA = action(10000, worker_div, worker_suma, worker_sdp, c_pid, 0, num1, num1,0)
	sumaB = action(10000, worker_div, worker_suma, worker_sdp, c_pid, 0, num1, sumaA,0)
	IO.puts(num1)
	#Comprueba que los dos numeros sean amigos (sumaA y num1) y los añade en la lista si no estaba ya el par
	if sumaB == num1 and sumaA != num1 and not(Enum.member?(listaPares,{sumaA,num1})), do: masterAux(worker_div, worker_suma, worker_sdp, num1+1, listaPares++[{num1,sumaA}], c_pid), else: masterAux(worker_div, worker_suma, worker_sdp, num1+1, listaPares, c_pid)
end


recibir_mensajes (timeout,worker_div, worker_suma, worker_sdp, c_pid, retry, idOperaciones, num) do
	receive do
		{:replyDiv, divisores, idOp, worker_div} ->
				if (idOp == idOperaciones) do
					send(worker_sum, {:reqWorkerSuma, {self(), divisores, idOperaciones}})
					sum = receive do
						{:replySuma, suma, idOp, worker_suma} -> 	
							if idOp == idOperaciones do
							 	suma 
							else
								if idOp == -1, do: send(worker_suma, {:reqWorkerSuma, {self(), num, idOperaciones}})	
								recibir_mensajes(timeout,worker_div, worker_suma, worker_sdp,c_pid,retry,idOperaciones,num)
							end
						#Compruebo si SDP ha acabado también, si ha acabado, eligo esta opción para no retrasar al cliente
						{:replySDP, sumDivisoresProp, idOp, worker_sdp} -> 		
							if idOp == idOperaciones do
							 	sumDivisoresProp 
							else
							 	if idOp == -1, do : send(worker_sdp, {:reqWorkerSDP, {self(), num, idOperaciones}})
							 	recibir_mensajes(timeout,worker_div, worker_suma, worker_sdp,c_pid,retry,idOperaciones,num)
							end

						after
							timeout -> action(timeout*(trunc(:math.pow(2,retry))), worker_div, worker_suma, worker_sdp, c_pid, retry+1, idOperaciones, num, 0) #Vuelve a intentar
						end
						sum	
				else
					if idOp == -1, do: send(worker_div, {:reqWorkerDiv, {self(), num, idOperaciones}})				
					recibir_mensajes(timeout,worker_div, worker_suma, worker_sdp,c_pid,retry,idOperaciones,num)
				end
				
		{:replySDP, sumDivisoresProp, idOp, worker_sdp} -> 		
			if idOp == idOperaciones do
			 	sumDivisoresProp 
			else 
				#Descarta operacion recibida
				if idOp == -1, do: send(worker_sdp, {:reqWorkerSDP, {self(), num, idOperaciones}})	
			 	recibir_mensajes(timeout,worker_div, worker_suma, worker_sdp,c_pid,retry,idOperaciones,num)
			end

		after
			timeout -> action(timeout*(trunc(:math.pow(2,retry))), worker_div, worker_suma, worker_sdp, c_pid, retry+1, idOperaciones, num, 0) #Vuelve a intentar
		end
    end

def action(timeout,worker_div, worker_suma, worker_sdp, c_pid, retry, idOperaciones, num, yaMandado) when retry < 5 do
	if yaMandado == 0 do
		send(worker_sdp, {:reqWorkerSDP, {self(), num, idOperaciones}})	#Envia al worker suma_divisores_propios la peticion
		send(worker_div, {:reqWorkerDiv, {self(), num, idOperaciones}})	#Envia al worker divisores_propios la peticion
	end
	recibir_mensajes(timeout,worker_div, worker_suma, worker_sdp, c_pid, retry, idOperaciones, num)
	end

#Si se llega al máximo numero de intentos se acaba la ejecución
def action(timeout,workers, c_pid, retry, idOperaciones, num, yaMandado) when retry == 5 do
 send(c_pid, {:reply, "timeout expiration"})
 exit(:shutdown)
end

end
