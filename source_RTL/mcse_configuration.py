import json

# Read parameters from mcse_config.json
with open('mcse_config.json', 'r') as json_file:
    config_data = json.load(json_file)
    ipid_N = config_data['ipid_N']
    ipid_address_map = config_data['ipid_address_map']

# Update mcse_def.svh file
with open('mcse_def.svh', 'r') as svh_file:
    lines = svh_file.readlines()

    for i, line in enumerate(lines):
        if '`define IPID_N' in line:
            lines[i] = '`define IPID_N {}\n'.format(ipid_N)
        elif '`define IPID_ADDR_MAP' in line:
            addr_map_str = ', '.join(ipid_address_map)
            lines[i] = '`define IPID_ADDR_MAP {{{}}}\n'.format(addr_map_str)

# Write updated content back to mcse_def.svh
with open('mcse_def.svh', 'w') as svh_file:
    svh_file.writelines(lines)

print("mcse_def.svh file has been updated.")
