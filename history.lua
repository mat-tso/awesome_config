-- This module provide a class that saves values and gives there averages

--save object
	function newhistory(taille_history, periode)
		local history = {}
		history.taille_history=taille_history or 100
		history.periode = periode or 1
		history.table = {}
		function history.add(element)
			if type(element)=="number" then
				table.insert(history.table,element)
				if #history.table>history.taille_history then
					table.remove(history.table,1)
				end
			end
		end
		function history.moy(temps)
			local nbvaleurTotal = #history.table
			local nbvaleur
			if type(temps)=="number" then
				nbvaleur = math.floor(temps/history.periode)
				if nbvaleur <= 0 then nbvaleur = 1 end
				if nbvaleur > nbvaleurTotal then nbvaleur = nbvaleurTotal end
			else nbvaleur = nbvaleurTotal
			end
			local sum = 0
			for i = (nbvaleurTotal - nbvaleur + 1),nbvaleurTotal do
				sum = sum + history.table[i]
			end
			return sum/nbvaleur,sum
		end
		return history
	end


