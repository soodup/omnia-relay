pullOracleTime () {
	local _assetPair="$1"
	local _address
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		error "Error - Invalid Oracle contract"
		return 1
	fi

	timeout -s9 10 ethereum call "$_address" "age()(uint32)" --rpc-url "$ETH_RPC_URL"
}

isFeedLifted () {
	local _assetPair="$1"
	local _feedAddr="$2"
	local _address
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		error "Error - Invalid Oracle contract"
		return 1
	fi

	[[ -z "$_feedAddr" ]] && {
		error "Error - feed address not passed"
		return 1
	}

	timeout -s9 10 ethereum call "$_address" "orcl(address)(uint256)" "$_feedAddr" --rpc-url "$ETH_RPC_URL"
}

pullOracleQuorum () {
	local _assetPair="$1"
	local _address
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		error "Error - Invalid Oracle contract"
		return 1
	fi

	timeout -s9 10 ethereum call "$_address" "bar()(uint256)" --rpc-url "$ETH_RPC_URL"
}

pullOraclePrice () {
	local _assetPair="$1"
	local _address
	local _rawStorage
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
			error "Error - Invalid Oracle contract"
			return 1
	fi

	_rawStorage=$(timeout -s9 10 ethereum storage "$_address" 0x1 --rpc-url "$ETH_RPC_URL")

	[[ "${#_rawStorage}" -ne 66 ]] && error "oracle contract storage query failed" && return

	ethereum --from-wei "$(ethereum --to-dec "${_rawStorage:34:32}")"
}

signTxBeforePush() {
	local _to="$1"
	local data="$2"
	local _fees="$3"

	# Using custom gas pricing strategy
	local _gasPrice="${_fees[0]}"
	local _gasPrio="${_fees[1]}"

	if [ "$_gasPrice" -eq "0" ]; then
		_gasPrice=$(ethereum gas-price --rpc-url "$ETH_RPC_URL")
	fi

#  _gasPrice=56067566576
	value=$(ethereum --to-wei "${ETH_VALUE:-0}")
	value=$(ethereum --to-hex "$value")

	args=(
		--from "$(ethereum --to-checksum-address "$ETH_FROM")"
		--nonce "${ETH_NONCE:-$(ethereum nonce --rpc-url "$ETH_RPC_URL" "$ETH_FROM")}"
		--chain-id "$(ethereum chain-id)"
		--gas-price "$_gasPrice"
		--gas-limit "${ETH_GAS:-200000}"
		--value "$value"
		--data "${data:-0x}"
		--to "$(ethereum --to-checksum-address "$_to")"
	)

	if [ $ETH_TX_TYPE -eq 2 ] && [ "$_gasPrio" ]; then
		args+=(--prio-fee "$_gasPrio")
	fi

	if [ -n "$ETH_PASSWORD" ]; then args+=(--passphrase-file "$ETH_PASSWORD"); fi

	tx=$([[ $OMNIA_VERBOSE ]] && set -x; ethsign tx "${args[@]}")
	echo "$tx"
}

pushOraclePrice () {
		local _assetPair="$1"
		local _oracleContract

		local _fees=($(getGasPrice))

		_oracleContract=$(getOracleContract "$_assetPair")
		if ! [[ "$_oracleContract" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		  error "Error - Invalid Oracle contract"
		  return 1
		fi

    # Encode the function call data.
#    local _calldata
#    _calldata=$(ethereum calldata 'getPrice(tuple[],bytes)' \
#        '[{"signature":"0x7bd1794db101d9a341eeb45308f40512fadf60a0460287b85f4e335c066f487a68543184651136799c34b0adf60be7cab857376fd804cbb1d3dd5be9c71a08fe28","feedId":1,"nonce":4,"timestamp":1699306911,"price":"66198561499975040000000000000000000000","extraData":"0x"}]' \
#        "0x")
#
#		log "Call data $_calldata ..."
#
#    # signing tx, cast dont support ethsign, so have to do it manually
#		local _txdata
#		if _txdata=$(signTxBeforePush $_oracleContract $_calldata $_fees)
#		then
#			verbose "Sign $_assetPair OK"
#		  log "Sending txdata $_txdata tx..."
#		else
#		  error "Sign $_assetPair Failed"
#		  return 1
#		fi
#
#		if [[ -z "$_txdata" ]]
#		then
#			error "Transaction is empty"
#			return 1
#		fi

#		log "Simulating $_assetPair tx..."
#		local _sim
#		if _sim=$(ethereum call "$_oracleContract" 'poke(uint256[] memory,uint256[] memory,uint8[] memory,bytes32[] memory,bytes32[] memory)' \
#							"[$(join "${allPrices[@]}")]" \
#							"[$(join "${allTimes[@]}")]" \
#							"[$(join "${allV[@]}")]" \
#							"[$(join "${allR[@]}")]" \
#							"[$(join "${allS[@]}")]" \
#							--rpc-url "$ETH_RPC_URL")

#    if _sim=$(ethereum call "$_oracleContract" 'getPrice(tuple[], bytes)' \
#                            '[{"signature":"0x7bd1794db101d9a341eeb45308f40512fadf60a0460287b85f4e335c066f487a68543184651136799c34b0adf60be7cab857376fd804cbb1d3dd5be9c71a08fe28","feedId":1,"nonce":4,"timestamp":1699306911,"price":"66198561499975040000000000000000000000","extraData":"0x"}]' \
#                            "0x" \
#                            --rpc-url "$ETH_RPC_URL")
#		then
#			verbose "Sim $_assetPair OK"
#		else
#		  error "Sim $_assetPair Failed"
#		  return 1
#		fi

  	local _gasPrice="${_fees[0]}"
    if [ "$_gasPrice" -eq "0" ]; then
      _gasPrice=$(ethereum gas-price --rpc-url "$ETH_RPC_URL")
    fi
    value=$(ethereum --to-wei "${ETH_VALUE:-0}")
    value=$(ethereum --to-hex "$value")
    nonce=${ETH_NONCE:-$(ethereum nonce --rpc-url "$ETH_RPC_URL" "$ETH_FROM")}

    # Define an array to hold the priceData objects
    # todo add feedId and extraData logic
    local priceDataArray=()
    for ((i = 0; i < ${#allPrices[@]}; i++)); do
      priceData="(0x${allR[i]}${allS[i]}${allV[i]},1,$nonce,${allTimes[i]},${allPrices[i]},0x)"
      priceDataArray+=("$priceData")
    done

    # Encode the priceDataArray to a JSON string.
    local priceDataJson="["
    for ((i = 0; i < ${#priceDataArray[@]}; i++)); do
      if [ $i -gt 0 ]; then
        priceDataJson+=","
      fi
      priceDataJson+="${priceDataArray[i]}"
    done
    priceDataJson+="]"

		log "PriceData json $priceDataJson ..."

		log "Sending $_assetPair tx..."

#		if tx=$(ethereum publish --async --rpc-url "$ETH_RPC_URL" "$_txdata")

		if tx=$(ethereum send "$_oracleContract" "getPrice((bytes,uint256,uint256,uint96,uint256,bytes)[],bytes)" "$priceDataJson" "0x" \
		--async --rpc-url "$ETH_RPC_URL" \
		--nonce "$nonce"\
		--gas-price "$_gasPrice" --gas-limit "${ETH_GAS:-200000}")

		then
			verbose "TX $_assetPair OK"
		else
		  error "TX $_assetPair Failed"
		  return 1
		fi

		if [[ -z "$tx" ]]
		then
			error "Receipt is empty"
			return 1
		fi

		_status="$(timeout -s9 60 ethereum receipt "$tx" status --rpc-url "$ETH_RPC_URL" )"
		_gasUsed="$(timeout -s9 60 ethereum receipt "$tx" gasUsed --rpc-url "$ETH_RPC_URL" )"

		# Monitoring node helper JSON
		verbose "Transaction receipt" "pair=$_assetPair" "tx=$tx" "type=$ETH_TX_TYPE" "maxGasPrice=${_fees[0]}" "prioFee=${_fees[1]}" "gasUsed=$_gasUsed" "status=$_status"
}
