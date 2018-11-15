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
	{sumaA, workerSDPA, workerDivA, workerSumaA} = action(10000, workerSDP, workerDiv, workerSuma, c_pid, 0, num1, num1,0)
	{sumaB, workerSDPB, workerDivB, workerSumaB} = action(10000, workerSDPA, workerDivA, workerSumaA, c_pid, 0, num1, sumaA,0)
	#Comprueba que los dos numeros sean amigos (sumaA y num1) y los añade en la lista si no estaba ya el par
	if sumaB == num1 and sumaA != num1 and not(Enum.member?(listaPares,{sumaA,num1})) do
		IO.puts (num1)
		IO.puts(sumaA)
		IO.puts("---------------")
	 	masterAux(workerSDPB, workerDivB, workerSumaB, num1+1, listaPares++[{num1,sumaA}], c_pid) 
	else 
	 	masterAux(workerSDPB, workerDivB, workerSumaB, num1+1, listaPares, c_pid)
	end
end


def action(timeout,workerSDP, workerDiv, workerSuma, c_pid, retry, idOperaciones, num, yaMandado) when retry < 5 do
	case yaMandado do
		0 -> send(workerSDP, {:reqWorkerSDP, {self(), num, idOperaciones}})	#Envia al worker suma_divisores_propios la peticion
			send(workerDiv, {:reqWorkerDiv, {self(), num, idOperaciones}})	#Envia al worker divisores_propios la peticion
		2 -> send(workerDiv, {:reqWorkerDiv, {self(), num, idOperaciones}})	#Envia al worker divisores_propios la peticion
		_ -> nil
	end
	result = receive do
		{:replyDiv, divisores, idOp, workerDiv_new} ->
			case idOp do
				-1 -> send(workerDiv_new, {:reqWorkerDiv, {self(), num, idOperaciones}})
						{sumaDP, wSDP, wDiv, wSum}=action(timeout,workerSDP, workerDiv_new, workerSuma,c_pid,retry,idOperaciones,num,1)
						{sumaDP, wSDP, workerDiv_new, wSum}
				idOperaciones -> send(workerSuma, {:reqWorkerSuma, {self(), divisores, idOperaciones}})
								res = receive do
									{:replySum, suma, idOp, workerSuma_new} -> 
																	case idOp do
																		-1 -> send(workerSuma_new, {:reqWorkerSuma, {self(), divisores, idOperaciones}})
																				{sumaDP, wSDP, wDiv, wSum}=action(timeout,workerSDP, workerDiv, workerSuma_new,c_pid,retry,idOperaciones,num,2)
																				{sumaDP, wSDP, wDiv, workerSuma_new}
																		idOperaciones -> {suma, workerSDP, workerDiv, workerSuma}
																		_ -> action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,2)
																	end
																	
									#Compruebo si SDP ha acabado también, si ha acabado, eligo esta opción para no retrasar al cliente
									{:replySDP, sumDivisoresProp, idOp, workerSDP_new} -> 
																case idOp do
																	-1 -> {sumaDP, wSDP, wDiv, wSum}=action(timeout,workerSDP_new, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,0)
																			{sumaDP, workerSDP_new, wDiv, wSum}
																	idOperaciones -> {sumDivisoresProp, workerSDP, workerDiv, workerSuma}
																	_ -> action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,2)
																end

								after
									timeout -> action(timeout*(trunc(:math.pow(2,retry))), workerSDP, workerDiv, workerSuma, c_pid, retry+1, idOperaciones, num, 0) #Vuelve a intentar
								end
								res
				_ -> action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,1)
			end
				
		{:replySDP, sumDivisoresProp, idOp, workerSDP_new} -> 
													case idOp do
														-1 -> send(workerSDP_new, {:reqWorkerSDP, {self(), num, idOperaciones}})	
															{sumaDP, wSDP, wDiv, wSum}=action(timeout,workerSDP_new, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,1)
															{sumaDP, workerSDP_new, wDiv, wSum}
														idOperaciones -> {sumDivisoresProp, workerSDP, workerDiv, workerSuma}
														_ -> action(timeout,workerSDP, workerDiv, workerSuma,c_pid,retry,idOperaciones,num,1)
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
