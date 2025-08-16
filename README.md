# WinIR-Script

Windows 시스템 침해사고(Incident Response, IR) 발생 시, 
증거 수집 및 1차 분석을 자동화하기 위한 PowerShell 기반 스크립트 툴킷이다.  
본 프로젝트는 ***KISA 침해사고 대응 매뉴얼***에서 제시된 절차를 참고하여 작성되었으며,  
실습 및 실제 환경에서 빠른 대응을 지원하기 위한 목적으로 설계되었다.  

---

## 프로젝트 구조

```
WinIR-Script/
│
├─ README.md # 프로젝트 개요 및 실행 방법
├─ main.ps1 # 메인 실행 스크립트 (전체 실행 흐름 제어)
│
├─ modules/ # 모듈화된 PowerShell 스크립트
│ ├─ collect.ps1 # 증거 수집 모듈
│ ├─ analyze.ps1 # 1차 분석 모듈
│ ├─ utils.ps1 # 공통 함수 (로그 기록, 경로 처리 등)
│ ├─ hashtools.ps1 # 해시 계산/검증
│ └─ compress.ps1 # 결과 압축
│
├─ config/
│ └─ settings.json # 외부 툴 경로, 결과 저장 경로 등 환경 설정
│
└─ results/
  └─ (실행 시 생성되는 YYYYMMDD_HHMM 폴더들)
```

---

## 요구사항

- Windows 10 이상
- PowerShell 5.1 이상 (기본 포함)
- **관리자 권한**으로 실행 필요
- 외부 툴 (Sysinternals, NirSoft) 설치 필요

---

## 외부 툴 설치 안내

본 프로젝트는 다음 외부 툴을 활용한다.  
저작권 문제로 저장소에 포함하지 않으므로 직접 설치해야 한다.

### 1. Sysinternals Suite

- 다운로드: [https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite](https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite)
- 권장 경로: `C:\Tools\Sysinternals`

### 2. NirSoft Utilities

- LastActivityView: [https://www.nirsoft.net/utils/computer_activity_view.html](https://www.nirsoft.net/utils/computer_activity_view.html)
- NetResView: [https://www.nirsoft.net/utils/netresview.html](https://www.nirsoft.net/utils/netresview.html)
- 권장 경로: `C:\Tools\NirSoft`

### 3. PATH 등록 (선택)

- 환경 변수 `PATH`에 위 경로들을 추가하면, 스크립트가 자동으로 해당 툴을 호출할 수 있다.  
- 등록하지 않는 경우, `config/settings.json`에서 직접 툴 경로를 지정해야 한다.

---

## 실행 방법

### 1. PATH 등록 후 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\main.ps1
```

### 2. 툴 경로를 직접 지정하여 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\main.ps1 -ToolsPath "C:\Tools"
```

---

## 출력 결과

실행 시, results/YYYYMMDD_HHMM/ 디렉토리가 자동 생성된다.
주요 결과물은 다음과 같다:

- collect.log → 증거 수집 로그
- analyze_report.txt → 1차 분석 결과
- registry/ → 레지스트리 hive 백업
- logs/ → 이벤트 로그 백업
- package.zip → 최종 압축본
- package.zip.sha256 → 무결성 검증 해시값

## 참고 문서

- docs/DESIGN.md : 모듈 설계 및 실행 흐름
- docs/TOOLS.md : 외부 툴 상세 설치 가이드

## 주의 사항

본 스크립트는 실습 및 연구 목적으로 작성되었다.
실제 사고 대응 시에는 반드시 조직의 보안 정책과 절차에 따라 활용해야 한다.
수집된 결과물에는 개인정보 및 민감한 데이터가 포함될 수 있으므로 적절한 보관/처리가 필요하다.
