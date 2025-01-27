#!/bin/ash
#
# Perform simplified MDIO register access to swtich ports
# meteowrite, Jan 2025 
#


# Function to check if a variable is hexadecimal and return its decimal value
is_hexadecimal() {
    input="$1"

    # Check if the input matches the hexadecimal pattern using `grep`
    if echo "$input" | grep -qE '^(0x|0X)?[0-9A-Fa-f]+$'; then
        # Convert the hexadecimal to decimal using `printf`
        if echo "$input" | grep -qE '^(0x|0X)'; then
            # Remove the '0x' or '0X' prefix
            input=$(echo "$input" | sed 's/^0[xX]//')
        fi
        decimal_value=$(printf "%d\n" "0x$input")
        echo "$decimal_value"
        return 0
    else
        echo "Error: Not a valid hexadecimal number."
        return 1
    fi
}


mdio_reg_read(){
    addr=$1;

    #get upper 10bits of address
    tmp1=$(((addr >> 9) & 0x3FF))

    phyad=0x18
    regad=0x00

    # write high address part
    mdio mdio.0 phy $phyad raw $regad $tmp1

    # prep low addr
    phyad=$((((addr >> 6) & 0x7) | 0x10 ))
    regad=$((((addr >> 1) & 0x1E) | 0x00 ))

    lo=$( mdio mdio.0 phy $phyad raw $regad )

    lo=$(is_hexadecimal "$lo")

    regad=$((regad | 0x01))
    hi=$( mdio mdio.0 phy $phyad raw $regad )

    hi=$(is_hexadecimal "$hi")

    #echo "$hi $lo"

    printf "0x%04X%04X\n" "$hi" "$lo"

}

mdio_reg_write(){
    addr=$1;
    data=$2;

    #get upper 10bits of address
    tmp1=$(((addr >> 9) & 0x3FF))

    lo=$((data & 0xFFFF ))
    hi=$(((data >> 16) & 0xFFFF ))

    phyad=0x18
    regad=0x00

    # write high address part
    mdio mdio.0 phy $phyad raw $regad $tmp1

    # prep low addr
    phyad=$((((addr >> 6) & 0x7) | 0x10 ))
    regad=$((((addr >> 1) & 0x1E) | 0x00 ))

    mdio mdio.0 phy $phyad raw $regad $lo

    regad=$((regad | 0x01))
    mdio mdio.0 phy $phyad raw $regad $hi


}

# Check the number of arguments
if [ "$#" -eq 1 ]; then
    # echo "You provided one argument: $1"
    # echo "Performing operation for a single argument..."
    # Add specific logic for one argument here

    mdio_reg_read "$1"

elif [ "$#" -eq 2 ]; then
    #echo "You provided two arguments: $1 and $2"
    #echo "Performing operation for two arguments..."
    # Add specific logic for two arguments here

    mdio_reg_write "$1" "$2"

else
    echo "Invalid number of arguments."
    echo "Usage: $0 <addr> [wdata]"
    exit 1
fi

