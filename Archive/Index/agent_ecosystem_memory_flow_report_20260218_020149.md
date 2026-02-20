# Agent Ecosystem Memory/Flow Report — 20260218_020149

Work root: `/home/architit/work`
Targets: `LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE`

## 1. Repository Footprint

| Repository | Agent Role | Files | Bytes |
|---|---|---:|---:|
| LAM-Codex_Agent | codex_core | 99 | 473992 |
| LAM_Comunication_Agent | communication_bus | 73 | 445773 |
| LAM_DATA_Src | memory_data_lake | 291 | 17310513 |
| Operator_Agent | operator_control | 80 | 526602 |
| Roaudter-agent | routing_core | 101 | 496788 |
| Trianiuma_MEM_CORE | memory_core | 9545 | 382865484 |

## 2. Memory Tier Distribution

| Repository | Operational | Long Term | Archival |
|---|---:|---:|---:|
| LAM-Codex_Agent | 35 | 19 | 45 |
| LAM_Comunication_Agent | 14 | 14 | 45 |
| LAM_DATA_Src | 8 | 238 | 45 |
| Operator_Agent | 19 | 15 | 46 |
| Roaudter-agent | 41 | 15 | 45 |
| Trianiuma_MEM_CORE | 723 | 8722 | 100 |

## 3. Process Stream Distribution

| Repository | Routing | Transport | Execution | Contract Control | Validation | Orchestration | Governance | General |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| LAM-Codex_Agent | 0 | 3 | 1 | 4 | 7 | 3 | 4 | 77 |
| LAM_Comunication_Agent | 0 | 2 | 0 | 4 | 2 | 3 | 4 | 58 |
| LAM_DATA_Src | 0 | 0 | 0 | 4 | 5 | 3 | 3 | 276 |
| Operator_Agent | 0 | 1 | 3 | 9 | 6 | 3 | 3 | 55 |
| Roaudter-agent | 10 | 0 | 1 | 4 | 17 | 5 | 4 | 60 |
| Trianiuma_MEM_CORE | 0 | 0 | 0 | 4 | 667 | 3 | 6 | 8865 |

## 4. Largest Files (Top 40)

| Repository | Path | Stream | Tier | Bytes |
|---|---|---|---|---:|
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/cv2.pyd` | general | long_term | 70967296 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/language-model.lm.bin` | general | long_term | 29208442 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/opencv_videoio_ffmpeg4120_64.dll` | general | long_term | 28349440 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/vosk/libstdc++-6.dll` | general | long_term | 26619146 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/vosk/libvosk.dll` | general | long_term | 26447872 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/numpy.libs/libscipy_openblas64_-13e2df515630b4a41f92893938845698.dll` | general | long_term | 20390912 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/PIL/_avif.cp312-win_amd64.pyd` | general | long_term | 7833600 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/primp/primp.pyd` | general | long_term | 7684608 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/pythonwin/mfc140u.dll` | general | long_term | 5664848 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/pydantic_core/_pydantic_core.cp312-win_amd64.pyd` | general | long_term | 5436928 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/numpy/_core/_multiarray_umath.cp312-win_amd64.pyd` | general | long_term | 4178432 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/lxml/etree.cp312-win_amd64.pyd` | general | long_term | 4113408 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/pronounciation-dictionary.dict` | general | long_term | 3240807 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/acoustic-model/mdef` | general | long_term | 2959176 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/data/haarcascade_frontalface_alt_tree.xml` | general | long_term | 2689040 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/PyWin32.chm` | general | long_term | 2646500 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/PIL/_imaging.cp312-win_amd64.pyd` | general | long_term | 2481152 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/flac-linux-x86_64` | general | long_term | 2396644 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/tiktoken/_tiktoken.cp312-win_amd64.pyd` | general | long_term | 2307584 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/numpy/_core/_simd.cp312-win_amd64.pyd` | general | long_term | 2236928 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/PIL/_imagingft.cp312-win_amd64.pyd` | general | long_term | 2063872 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/acoustic-model/sendump` | general | long_term | 1969024 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/flac-linux-x86` | general | long_term | 1899154 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/lxml/objectify.cp312-win_amd64.pyd` | general | long_term | 1754112 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/GEMINI/RADRILONIUMA_2026_01.V.0.2-GMN.txt` | general | long_term | 1572098 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/pythonwin/scintilla.dll` | general | long_term | 1500160 |
| LAM_DATA_Src | `LAM_DATA_Src/LAM_MEM_C(K).1.txt` | general | long_term | 1447564 |
| LAM_DATA_Src | `LAM_DATA_Src/Workflows/Onedrive/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).1.txt` | general | long_term | 1414096 |
| LAM_DATA_Src | `LAM_DATA_Src/Workflows/Onedrive/LRAM/LAM_MEM_C(K).1.txt` | general | long_term | 1414096 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).1.txt` | general | long_term | 1414096 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LRAM/LAM_MEM_C(K).1.txt` | general | long_term | 1414096 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/pythonwin/win32ui.pyd` | general | long_term | 1051648 |
| LAM_DATA_Src | `LAM_DATA_Src/Workflows/Onedrive/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).15.txt` | general | long_term | 932491 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).15.txt` | general | long_term | 932491 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/data/haarcascade_frontalface_default.xml` | general | long_term | 930127 |
| LAM_DATA_Src | `LAM_DATA_Src/Workflows/Onedrive/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).2.0.txt` | general | long_term | 888598 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).2.0.txt` | general | long_term | 888598 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/acoustic-model/means` | general | long_term | 838732 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/acoustic-model/variances` | general | long_term | 838732 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/data/haarcascade_profileface.xml` | general | long_term | 828514 |

## Artifacts
- Agent matrix TSV: `/home/architit/work/Archivator_Agent/Archive/Index/agent_ecosystem_file_matrix_20260218_020149.tsv`
- Latest TSV pointer: `/home/architit/work/Archivator_Agent/Archive/Index/agent_ecosystem_file_matrix_latest.tsv`
- Latest report pointer: `/home/architit/work/Archivator_Agent/Archive/Index/agent_ecosystem_memory_flow_report_latest.md`
