import json

# Read parameters from mcse_config.json
with open('mcse_config.json', 'r') as json_file:
    config_data = json.load(json_file)
    ipid_N = config_data['ipid_N']
    ipid_width = config_data["puf_size"]
    ipid_address_map = config_data['ipid_address_map']
    scan_key_width = config_data['scan_key_width']
    lifecycle_authentication_key = config_data['lifecycle_authentication_key']
    lifecycle_transition_key = config_data['lifecycle_transition_key']
    encryption_function = config_data['encryption_function']

# Update mcse_def.svh file
with open('mcse_def.svh', 'r') as svh_file:
    lines = svh_file.readlines()

    for i, line in enumerate(lines):
        if '`define IPID_N' in line:
            lines[i] = '`define IPID_N {}\n'.format(ipid_N)
        elif '`define IPID_WIDTH' in line:
            lines[i] = '`define IPID_WIDTH {}\n' .format(ipid_width)
        elif '`define IPID_ADDR_MAP' in line:
            addr_map_str = ', '.join(ipid_address_map)
            lines[i] = '`define IPID_ADDR_MAP {{{}}}\n'.format(addr_map_str)
        elif '`define SCAN_KEY_WIDTH' in line:
            lines[i] = '`define SCAN_KEY_WIDTH {}\n' .format(scan_key_width)
        elif '`define SECURE_MEMORY_WIDTH' in line:
            lines[i] = '`define SECURE_MEMORY_WIDTH {}\n' .format(lifecycle_authentication_key)
        elif '`define LC_MEMORY_WIDTH' in line:
            lines[i] = '`define LC_MEMORY_WIDTH {}\n' .format(lifecycle_transition_key)
        elif '`define ENCRYPTION_FUNCTION' in line:
            lines[i] = '`define ENCRYPTION_FUNCTION "{}"\n' .format(encryption_function)
        

# Write updated content back to mcse_def.svh
with open('mcse_def.svh', 'w') as svh_file:
    svh_file.writelines(lines)

print("mcse_def.svh file has been updated.")