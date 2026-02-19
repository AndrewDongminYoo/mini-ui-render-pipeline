# Mini UI Render Pipeline과 Flutter 실제 파이프라인 비교

## 0) 한 줄 요약

- 과제는 **“이벤트 리스트 → 엔진이 트리 직접 변경 → dirty 수집/정렬 → 레이아웃 계산 → 결과(JSON) 생성”** 이라는 **배치 처리형(offline) 파이프라인**입니다.
- Flutter는 **“프레임 단위(VSync)로 Build/Layout/Paint/Composite를 수행”** 하는 **프레임 기반(online) retained 렌더러**입니다. 출력은 JSON이 아니라 **GPU에 합성되는 Layer tree(그리고 Semantics tree)** 입니다.

## 1) 트리 계층 구조: 과제는 1트리, Flutter는 2~3트리

### 과제

- 사실상 **NodeTree 하나**로 끝납니다.
  - Node가 `size/position/state/children` + `structureDirty/layoutDirty` 를 모두 들고 있음.

### Flutter

- 최소 2단(실제로는 3단) 트리입니다.
  1. **Widget tree** (불변 선언, “설계도”)
  2. **Element tree** (위젯 인스턴스/상태/재사용 판단, “관리자”)
  3. **RenderObject tree** (레이아웃/페인트/hitTest, “실행자”)

#### **차이의 핵심**

- 과제는 “모델 트리 = 렌더 트리”.
- Flutter는 “선언(Widget) ↔ 유지/재사용(Element) ↔ 렌더(RenderObject)”가 분리되어 **업데이트 비용과 상태 보존**을 제어합니다.

## 2) 이벤트 모델: “외부 이벤트 리스트” vs “상태 변경 → markNeeds\*”

### 과제

- 입력이 **Event List**로 명시적입니다. (`SetSize`, `AddChild`, `SetState` 등)
- Engine이 이벤트를 해석하고 Node를 직접 mutate한 뒤, dirty를 수동으로 마킹합니다.

### Flutter

- 보통 “이벤트 리스트”를 프레임워크가 받지 않습니다.
- 개발자/프레임워크가 **상태 변경을 트리 내부에서 발생**시키고,
  - `setState()` → 다음 프레임에서 **build 재실행** 예약
  - RenderObject 변경 → `markNeedsLayout()`, `markNeedsPaint()`, `markNeedsSemanticsUpdate()` 등으로 **파이프라인에 예약**합니다.

#### **차이의 핵심**

- 과제: “이벤트가 1급 객체(입력)”
- Flutter: “상태 변경이 1급 사건이고, 엔진은 *dirty bit*로 프레임을 재구성”

## 3) Dirty의 종류와 전파: 과제는 2-tier, Flutter는 더 세분화 + 전파 규칙이 다름

### 과제

- `structureDirty`, `layoutDirty` **2-tier**
- 전파 규칙이 과제 요구사항 중심(예: setSize → sibling까지 layoutDirty)

### Flutter

- RenderObject 쪽 dirty는 보통 다음 축으로 나뉩니다.
  - **needsLayout** (레이아웃 필요)
  - **needsPaint** (그리기 필요)
  - **needsCompositing** (합성 관련)
  - **needsSemantics** (접근성 트리 갱신)

- 전파 방향도 다릅니다.
  - `markNeedsLayout()`은 일반적으로 **부모 방향(상향)으로** 전파되어 “재레이아웃 루트”를 잡고,
  - 실제 layout은 **부모→자식(하향)** 으로 constraints를 내려 보내며 수행됩니다.
  - sibling을 직접 dirty로 찍는 식이 아니라, **부모가 자식들의 배치를 다시 계산**하면서 결과적으로 sibling 위치가 바뀝니다.

#### **차이의 핵심**

- 과제는 “형제까지 dirty로 명시 표시”로 결과 리스트를 맞춤.
- Flutter는 “부모 레이아웃 재실행”으로 sibling 영향이 **암묵적으로 처리**됩니다.

## 4) 레이아웃 계산 방식: 과제는 “자식 size 합산”, Flutter는 “Constraints 기반(top-down)”

### 과제

- Row/Column/Stack이 **자식들의 size를 합산/최댓값**으로 부모 size를 계산합니다.
- cascading을 fixed-point iteration으로 수렴시킵니다. (자식 변경 → 부모 dirty → 반복)

### Flutter

- 레이아웃은 기본적으로 **Constraints 기반**입니다.

  **부모가 constraints를 내려주고 → 자식이 그 constraints 안에서 size를 결정 → 부모가 자식들의 위치를 결정**하는 흐름(Top-down constraints, Bottom-up size reporting 혼합)이지만,
  핵심은 “**부모가 레이아웃의 주도권을 가진다**” 입니다.

- 일반적 RenderBox의 레이아웃은 fixed-point 반복보다는,
  - `layout(constraints)` 호출 체인이 **정해진 순서**로 진행되며,
  - 특정 케이스에서만 추가 패스(예: intrinsic 측정, dry layout 등)가 개입합니다.

#### **차이의 핵심**

- 과제는 “자식의 size가 곧 진실 → 부모는 합산”
- Flutter는 “부모의 constraints가 곧 진실 → 자식은 그 안에서 결정”

## 5) 스케줄링 단위: 과제는 “이벤트마다 즉시”, Flutter는 “프레임(=VSync)마다”

### 과제

- 이벤트 1개 처리 후 즉시:
  - dirty 수집
  - 레이아웃 계산
  - 결과 생성
  - dirty clear

### Flutter

- **Scheduler가 프레임 단위로 묶습니다.**
  - 한 프레임에서 여러 변경이 합쳐지고(coalescing),
  - Build → Layout → Paint → Composite(그리고 Semantics) 순서로 한 번에 처리합니다.

#### **차이의 핵심**

- 과제는 “이벤트 단위의 eager 평가”
- Flutter는 “프레임 단위의 배치 + 합치기(coalescing)”

## 6) “Paint order”의 의미: 과제는 DFS 리스트, Flutter는 실제 Layer 합성(클립/트랜스폼/오버레이 포함)

### 과제

- paintOrder = **pre-order DFS로 노드 id 나열**
- 결과물은 “순서 리스트”가 핵심 산출물 중 하나

### Flutter

- RenderObject의 `paint()`는 **Canvas에 직접 그리는 것처럼 보이지만**,
  실제로는 많은 경우 **Layer tree**를 만들고,
  - clip, opacity, transform, saveLayer, platform view, texture 등이 끼면
  - 단순 DFS 순서가 아니라 **합성 규칙**이 주요 변수가 됩니다.

- 또한 repaint boundary 등으로 subtree를 캐시/재사용할 수도 있어 “항상 전체를 다시 그린다”는 보장이 없습니다.

#### **차이의 핵심**

- 과제의 paintOrder는 “설명용 정렬”
- Flutter의 paint는 “GPU 합성을 위한 그래프 구성”에 가깝고, 순서만으로 설명이 끝나지 않습니다.

## 7) “구조 변경” 처리: 과제는 structureDirty, Flutter는 Widget diff + Element 재사용(키)

### 과제

- add/remove가 발생하면 structureDirty로 “재구조화 필요 노드”를 결과로 뽑습니다.

### Flutter

- 구조 변경은 주로 **Widget tree diff**에서 시작합니다.
  - 같은 타입/키면 Element를 재사용하고,
  - 아니면 subtree를 버리고 새로 만듭니다.

- 즉, “구조 변경 감지/반영” 자체가 **Element 업데이트 알고리즘**의 영역입니다.
- RenderObject는 그 결과로 attach/detach/child list 변경을 겪고 dirty가 예약됩니다.

#### **차이의 핵심**

- 과제는 “노드가 구조 변경을 직접 표시”
- Flutter는 “Widget diff/Key가 구조 재사용을 결정”

## 8) 출력의 목적: 과제는 “디버깅 가능한 결정적 JSON”, Flutter는 “화면에 그리기 + 접근성”

### 과제

- 출력 = `EventResult(recomputeStructure, recomputeLayout, paintOrder)` 같은 **설명용/채점용 결과**.

### Flutter

- 출력 = 최종적으로 **엔진이 rasterize/composite 한 프레임** + **Semantics tree 업데이트**.
- 프레임워크가 “어떤 노드가 recomputeLayout에 들어갔는지”를 API로 리턴하지 않습니다(내부 디버그/프로파일링에서만 관찰).

## 매핑 테이블 (빠른 대비)

| 과제 컴포넌트                | Flutter에서 대응되는 개념                      | 핵심 차이                       |
| ---------------------------- | ---------------------------------------------- | ------------------------------- |
| NodeTree + Node              | RenderObject tree (그리고 Widget/Element)      | Flutter는 트리가 분리됨         |
| Engine.processEvent(Event)   | setState / RenderObject mutation + markNeeds\* | “이벤트 리스트”가 입력이 아님   |
| structureDirty               | Widget diff + Element 업데이트/키              | 구조는 Element 레벨에서 해결    |
| layoutDirty                  | RenderObject.needsLayout                       | sibling dirty를 직접 찍지 않음  |
| Scheduler.collect/Order      | PipelineOwner + SchedulerBinding(프레임)       | 프레임 단위 coalescing          |
| LayoutCalculator.recalculate | RenderObject.performLayout (constraints 기반)  | 계산 모델이 다름                |
| Renderer.paintOrder DFS      | paint() + Layer tree composition               | 합성/캐시/클립이 개입           |
| 결과 JSON                    | 화면 프레임 + semantics 업데이트               | “설명용 리스트”를 리턴하지 않음 |
