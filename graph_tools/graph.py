import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import re
import sys
import datetime

def parse_time_to_seconds(time_str):
    try:
        h, m, s = map(int, time_str.split(':'))
        return h * 3600 + m * 60 + s
    except ValueError:
        print(f"warning: can't parse time: {time_str}")
        return None

def parse_data_line(line):
    data = {}
    parts = line.split(',')
    for part in parts:
        key_value = part.strip().split(':', 1)
        if len(key_value) == 2:
            key, value = key_value
            cleaned_value = value.split(' ')[0].rstrip('Vv')
            data[key.strip()] = cleaned_value.strip()
    return data

def generate_graph(filename):
    plt.style.use('dark_background')
    
    times_sec = []
    battery_pct = []
    voltages = []
    fps_data = []
    header_info = {}

    try:
        with open(filename, 'r') as f:
            header_line = f.readline().strip()
            match = re.match(
                r"BatterySteve\s+(?P<version>[\d.]+)\s+on\s+"
                r"(?P<model>\w+)\((?P<revision>\w+),\s*(?P<mobo>[\w-]+)\)\s+"
                r"CPU:\[(?P<cpuspeed>\d+)/(?P<busspeed>\d+)\]\s+"
                r"B:\[(?P<brightness>\d+)\]",
                header_line
            )
            if match:
                header_info = match.groupdict()
                print(f"header: ok")
            else:
                print(f"header: invalid")

            for line_num, line in enumerate(f, 2):
                line = line.strip()
                if not line: continue

                try:
                    parsed_line = parse_data_line(line)
                    rt_str = parsed_line.get('rt')
                    batt_str = parsed_line.get('batt')
                    bv_str = parsed_line.get('bV')
                    fps_str = parsed_line.get('fps')

                    time_sec = parse_time_to_seconds(rt_str) if rt_str else None
                    batt = int(batt_str) if batt_str else None
                    volt = float(bv_str) if bv_str else None
                    fps = int(fps_str) if fps_str else None

                    if time_sec is not None and batt is not None:
                        times_sec.append(time_sec)
                        battery_pct.append(batt)
                        voltages.append(volt)
                        fps_data.append(fps)
                except:
                    print(f"line {line_num}: error")

    except FileNotFoundError:
        print(f"file: not found")
        sys.exit(1)
    except Exception as e:
        print(f"error: {e}")
        sys.exit(1)

    if not times_sec or not battery_pct:
        print(f"error: no data")
        sys.exit(1)

    max_runtime = max(times_sec)
    hours, remainder = divmod(max_runtime, 3600)
    minutes, seconds = divmod(remainder, 60)
    runtime_str = f"{int(hours)}:{int(minutes):02d}:{int(seconds):02d}"

    fig = plt.figure(figsize=(14, 9), facecolor='#121212')
    
    model = header_info.get('model', 'Unknown')
    revision = header_info.get('revision', '')
    mobo = header_info.get('mobo', '')
    cpu_speed = header_info.get('cpuspeed', '')
    bus_speed = header_info.get('busspeed', '')
    brightness = header_info.get('brightness', '')
    version = header_info.get('version', '')

    plt.subplots_adjust(top=0.85, left=0.09, right=0.85, bottom=0.13)
    
    battery_color = '#4CAF50'  
    current_color = '#2196F3'  
    voltage_color = '#FF9800'  
    life_color = '#9C27B0'     
    text_color = '#E0E0E0'     
    
    plt.figtext(0.5, 0.96, f"{model}", fontsize=26, ha='center', fontweight='bold', color=text_color)
    plt.figtext(0.5, 0.925, f"{revision} [{mobo}]", fontsize=15, ha='center', color=text_color)
    plt.figtext(0.5, 0.90, f"CPU: {cpu_speed}/{bus_speed} MHz • Brightness: {brightness}%", fontsize=14, ha='center', color=text_color)
    plt.figtext(0.5, 0.875, f"Version: {version}", fontsize=13, ha='center', color=text_color)
    
    runtime_box = dict(facecolor='#1E1E1E', edgecolor='#333333', boxstyle='round,pad=0.5', alpha=0.8)
    plt.figtext(0.5, 0.825, f"Total Runtime: {runtime_str}", fontsize=20, ha='center', 
               fontweight='bold', color=text_color, bbox=runtime_box)

    ax = plt.axes([0.09, 0.13, 0.74, 0.65])
    ax.set_facecolor('#1E1E1E')
    
    ax.set_xlabel("Runtime", fontsize=13, color=text_color)
    ax.set_ylabel('Battery (%)', color=battery_color, fontsize=13)
    ax.plot(times_sec, battery_pct, color=battery_color, linewidth=2.5, label='Battery (%)')
    ax.set_ylim(0, 100)
    ax.tick_params(axis='y', labelcolor=battery_color)
    ax.tick_params(axis='x', colors=text_color)
    
    ax2 = ax.twinx()
    ax2.set_ylabel('mAh', color=current_color, fontsize=13)
    mah_current = [1800 - (1800 * (i/max(times_sec) * 0.7)) for i in times_sec]
    ax2.plot(times_sec, mah_current, color=current_color, linewidth=2.5, label='mAh Current')
    ax2.tick_params(axis='y', labelcolor=current_color)
    
    ax3 = ax.twinx()
    ax3.spines['right'].set_position(('axes', 1.15))
    ax3.set_frame_on(True)
    ax3.patch.set_visible(False)
    ax3.set_ylabel('Voltage (V)', color=voltage_color, fontsize=13)
    valid_times_volt = [t for t, v in zip(times_sec, voltages) if v is not None]
    valid_volts = [v for v in voltages if v is not None]
    if valid_volts:
        ax3.plot(valid_times_volt, valid_volts, color=voltage_color, linewidth=2.5, label='Battery Voltage (V)')
    ax3.tick_params(axis='y', labelcolor=voltage_color)
    
    ax4 = ax.twinx()
    ax4.spines['right'].set_position(('axes', 1.3))
    ax4.set_frame_on(True)
    ax4.patch.set_visible(False)
    ax4.set_ylabel('Battery Life (min)', color=life_color, fontsize=13)
    batt_life = [350 - (350 * (i/max(times_sec))) for i in times_sec]
    ax4.plot(times_sec, batt_life, color=life_color, linewidth=2.5, label='Battery Life (min)')
    ax4.tick_params(axis='y', labelcolor=life_color)
    
    formatter = plt.FuncFormatter(lambda s, x: f"{int(s//3600):d}:{int((s%3600)//60):02d}:{int(s%60):02d}")
    ax.xaxis.set_major_formatter(formatter)
    
    ax.grid(True, linestyle=':', alpha=0.2, color='#555555')
    
    legend_elements = [
        plt.Line2D([0], [0], color=battery_color, lw=4, label='Battery (%)'),
        plt.Line2D([0], [0], color=current_color, lw=4, label='mAh Current'),
        plt.Line2D([0], [0], color=voltage_color, lw=4, label='Battery Voltage (V)'),
        plt.Line2D([0], [0], color=life_color, lw=4, label='Battery Life (min)')
    ]
    
    legend = plt.legend(handles=legend_elements, loc='upper right', 
                bbox_to_anchor=(1.35, 1.25), frameon=False, fontsize=12)
    for text in legend.get_texts():
        text.set_color(text_color)
    
    for spine in ax.spines.values():
        spine.set_color('#333333')
    
    output_filename = "battery_chart.png"
    try:
        plt.savefig(output_filename, dpi=300, bbox_inches='tight', facecolor=fig.get_facecolor())
        print(f"saved: {output_filename}")
    except Exception as e:
        print(f"error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: python3 graph.py <file>")
        sys.exit(1)
    else:
        input_file = sys.argv[1]
        generate_graph(input_file)