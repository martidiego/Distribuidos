# AUTORES: 
# NIAs: numeros de identificacion de los alumnos
# FICHERO: nombre del fichero
# FECHA: 15 noviembre
# TIEMPO: tiempo en horas de codificacion
# DESCRIPCION: breve descripcion del contenido del fichero

defmodule Master do


def master(workerSDP, workerDiv, workerSuma) do
	receive do
		{c_pid, num1, :req} -> masterAux(workerSDP, workerDiv, workerSuma, num1, [], c_pid)
	end
	master(workerSDP, workerDiv, workerSuma)
end


defp masterAux(workerSDP, workerDiv, workerSuma, num1, listaPares, c_pid) when num1 > 20000 do
	send(c_pid, {:reply, listaPares})
end


#Calcula los pares de numeros amigos desde num1 hasta n
defp masterAux(workerSDP, workerDiv, workerSuma, num1, listaPares, c_pid) do
	IO.puts(num1)
	sumaA = action(10000, workerSDP, workerDiv, workerSuma, c_pid, 0, num1, num1,0)
	sumaB = action(10000, workerSDP, workerDiv, workerSuma, c_pid, 0, num1, sumaA,0)
	#Comprueba que los dos numeros sean amigos (sumaA y num1) y los añade en la lista si no estaba ya el par
	if sumaB == num1 and sumaA != num1 and not(Enum.member?(listaPares,{sumaA,num1})) do
		IO.puts (num1)
		IO.puts(sumaA)
		IO.puts("---------------")
	 	masterAux(workerSDP, workerDiv, workerSuma, num1+1, listaPares++[{num1,sumaA}], c_pid) 
	else 
	 	masterAux(workerSDP, workerDiv, workerSuma, num1+1, listaPares, c_pid)
	end
end


def action(timeout,workerSDP, workerDiv, workerSuma, c_pid, retry, idOperaciones, num, yaMandado) when retry < 5 do
	if yaMandado == 0 do
		send(workerSDP, {:reqWorkerSDP, {self(), num, idOperaciones}})	#Envia al worker suma_divisores_propios la peticion
		send(workerDiv, {:reqWorkerDiv, {self(), num, idOperaciones}})	#Envia al worker divisores_propios la peticion
	end
	result = receive do
		{:replyDiv, divisores, idOp, workerDiv} ->
				if (idOp == -1), do: send(workerDiv, {:reqWorkerDiv, {self(), num, idOperaciones}})
				if (idOp == idOperaciones) do
					sum = receive do
						{:replySuma, suma, idOp, workerSuma} -> 
														if (idOp == -1), do: send(workerSuma, {:reqWorkerSuma, {self(), num, idOperaciones}})	
														if idOp == idOperaciones do
														 	suma 
														else
															action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,0)
														end
						#Compruebo si SDP ha acabado también, si ha acabado, eligo esta opción para no retrasar al cliente
						{:replySDP, sumDivisoresProp, idOp, workerSDP_new} -> 
													if (idOp == -1), do: send(workerSDP_new, {:reqWorkerSDP, {self(), num, idOperaciones}})		
													if idOp == idOperaciones do
													 	sumDivisoresProp 
													else
													 	action(timeout,workerSDP_new, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,0)
													end

					after
						timeout -> action(timeout*(trunc(:math.pow(2,retry))), workerSDP, workerDiv, workerSuma, c_pid, retry+1, idOperaciones, num, 0) #Vuelve a intentar
					end
					sum
				else
					#Descarta respuesta recibida
					action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,1)
				end
				
		{:replySDP, sumDivisoresProp, idOp, workerSDP} -> 
													if (idOp == -1), do: send(workerSDP, {:reqWorkerSDP, {self(), num, idOperaciones}})		
													if idOp == idOperaciones do
													 	sumDivisoresProp 
													else
														#Descarta operacion recibida
													 	action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,1)
													end
	after
		timeout -> action(timeout*(trunc(:math.pow(2,retry))), workerSDP, workerDiv, workerSuma, c_pid, retry+1, idOperaciones, num, 0) #Vuelve a intentar
	end
	result
end

#Si se llega al máximo numero de intentos se acaba la ejecución
def action(timeout,workerSDP, workerDiv, workerSuma, c_pid, retry, idOperaciones, num, yaMandado) when retry == 5 do
 send(c_pid, {:reply, "timeout expiration"})
 exit(:shutdown)
end

end
