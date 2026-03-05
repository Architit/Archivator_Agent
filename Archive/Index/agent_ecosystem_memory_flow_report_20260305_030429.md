# Agent Ecosystem Memory/Flow Report — 20260305_030429

Work root: `/home/architit/work`
Targets: `LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE`

## 1. Repository Footprint

| Repository | Agent Role | Files | Bytes |
|---|---|---:|---:|
| LAM-Codex_Agent | codex_core | 312 | 856084 |
| LAM_Comunication_Agent | communication_bus | 280 | 800556 |
| LAM_DATA_Src | memory_data_lake | 131 | 5235961 |
| Operator_Agent | operator_control | 288 | 892893 |
| Roaudter-agent | routing_core | 307 | 850403 |
| Trianiuma_MEM_CORE | memory_core | 9820 | 383856624 |

## 2. Memory Tier Distribution

| Repository | Operational | Long Term | Archival |
|---|---:|---:|---:|
| LAM-Codex_Agent | 43 | 224 | 45 |
| LAM_Comunication_Agent | 22 | 213 | 45 |
| LAM_DATA_Src | 10 | 121 | 0 |
| Operator_Agent | 24 | 218 | 46 |
| Roaudter-agent | 44 | 218 | 45 |
| Trianiuma_MEM_CORE | 727 | 8992 | 101 |

## 3. Process Stream Distribution

| Repository | Routing | Transport | Execution | Contract Control | Validation | Orchestration | Governance | General |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| LAM-Codex_Agent | 0 | 3 | 1 | 3 | 13 | 3 | 28 | 261 |
| LAM_Comunication_Agent | 0 | 2 | 0 | 4 | 10 | 3 | 28 | 233 |
| LAM_DATA_Src | 0 | 0 | 0 | 4 | 6 | 3 | 4 | 114 |
| Operator_Agent | 0 | 1 | 3 | 8 | 11 | 3 | 27 | 235 |
| Roaudter-agent | 10 | 0 | 1 | 3 | 24 | 5 | 28 | 236 |
| Trianiuma_MEM_CORE | 0 | 0 | 0 | 3 | 671 | 3 | 30 | 9113 |

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
| LAM_DATA_Src | `LAM_DATA_Src/data/source/LAM_MEM_C(K).1.txt` | general | long_term | 1447564 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).1.txt` | general | long_term | 1414096 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LRAM/LAM_MEM_C(K).1.txt` | general | long_term | 1414096 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/pythonwin/win32ui.pyd` | general | long_term | 1051648 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).15.txt` | general | long_term | 932491 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/data/haarcascade_frontalface_default.xml` | general | long_term | 930127 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/LAM/LAM_MEM_ANAYAMASPECULUM/ARCHI_SUB/L_M_C_U_(K)/C_U_KYRYLO_LIAPUSTIN/LAM_MEM_C(K).2.0.txt` | general | long_term | 888598 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/acoustic-model/means` | general | long_term | 838732 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/pocketsphinx-data/en-US/acoustic-model/variances` | general | long_term | 838732 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/data/haarcascade_profileface.xml` | general | long_term | 828514 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/cv2/data/haarcascade_upperbody.xml` | general | long_term | 785819 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/speech_recognition/flac-win32.exe` | general | long_term | 738816 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/regex/_regex.cp312-win_amd64.pyd` | general | long_term | 724992 |
| Trianiuma_MEM_CORE | `Trianiuma_MEM_CORE/RAM_MEM/Sys/ATPLT/autopilot_package/venv/Lib/site-packages/numpy/random/_generator.cp312-win_amd64.pyd` | general | long_term | 714752 |

## Artifacts
- Agent matrix TSV: `/home/architit/work/Archivator_Agent/Archive/Index/agent_ecosystem_file_matrix_20260305_030429.tsv`
- Latest TSV pointer: `/home/architit/work/Archivator_Agent/Archive/Index/agent_ecosystem_file_matrix_latest.tsv`
- Latest report pointer: `/home/architit/work/Archivator_Agent/Archive/Index/agent_ecosystem_memory_flow_report_latest.md`
