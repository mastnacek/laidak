# Co nemáme ve Flutter TODO aplikaci (oproti Python TODO aplikaci)

**Dokument analyzuje rozdíly mezi funkcemi implementovanými v Python TODO aplikaci a současnou Flutter/Dart TODO aplikací.**

**Datum analýzy:** 16. 10. 2025  
**Zdroj:** Analýza zdrojového kódu Python TODO aplikace (G:\todo_python_vzor)

---

## 🎯 Přehled

Python TODO aplikace obsahuje pokročilý **4-fázový Anti-Procrastination System** s AI integrací, který není ve Flutter aplikaci implementován. Hlavní rozdíl je v komplexním systému pro podporu produktivity, formování návyků a prevenci vyhoření.

---

## 📊 KLÍČOVÉ FUNKCE CO NEMÁME

### 1. ☀️ **Morning Ritual System (Ranní rituál)**

**Soubor:** `ritual_engine.py`, `routes_ritual.py`

**Co dělá:**
- **Ranní intention setting** - nastavení denního záměru
- AI generuje **3-5 návrhů** co je dnes důležité na základě:
  - Nedokončené úkoly (prioritní + po termínu)
  - Výkon včera (deep work hours, dokončené úkoly, focus quality)
  - Aktuální čas a den v týdnu
- Uživatel vyplní:
  - **Primary goal** - hlavní cíl dne
  - **Energy level** (1-10 škála) - odhadovaná energie
  - **Expected hours** - kolik hodin má uživatel k dispozici (0.5-12.0)
  - **Work context** - kde bude pracovat (home/office/mobile)
  - **Mood rating** (1-10) - aktuální nálada
  - **Stress level** (1-10) - úroveň stresu

**Implementace:**
```python
class WorkRitualEngine:
    def morning_intention(self, user_id: int) -> IntentionData:
        # Získá pending tasks
        # Analyzuje včerejší metriky (ProductivityMetrics)
        # Generuje AI suggestions (až 5 návrhů)
        # Vrací IntentionData s primary_goal, energy_level, ai_suggestions
```

**Databáze:**
```python
class DailyIntention(db.Model):
    primary_goal = db.Column(db.Text, nullable=False)
    energy_level = db.Column(db.Integer, nullable=False)  # 1-10
    expected_hours = db.Column(db.Float, nullable=False)
    work_context = db.Column(db.String(50))
    mood_rating = db.Column(db.Integer)
    stress_level = db.Column(db.Integer)
    ai_suggestions = db.Column(JSON, default=list)
    
    # Evening reflection
    evening_reflection = db.Column(db.Text)
    satisfaction_rating = db.Column(db.Integer)  # 1-10
    lessons_learned = db.Column(db.Text)
```

**UI Route:** `/ritual/morning`

---

### 2. 🧘 **Guided Breathing Exercises (Řízené dechové cvičení)**

**Soubor:** `ritual_engine.py` (metoda `guided_breathing_session`), `wellness.py` (metoda `get_breathing_exercise`)

**Co dělá:**
- **3 typy dechových cvičení:**
  1. **4-7-8 Dýchání** - klasická relaxační technika (2 min)
  2. **Krabicové dýchání (Box Breathing)** - pro uklidnění a soustředění (3 min)
  3. **Trojité dýchání** - rychlé zklidnění (1 min)

- **Guided instructions** - krok po kroku návod
- **Doporučená délka** - každé cvičení má svůj čas
- **Random selection** - náhodný výběr cvičení

**Implementace:**
```python
def guided_breathing_session(self, duration: int = 30) -> Dict:
    return {
        'duration': 30,
        'pattern': 'box_breathing',  # 4-4-4-4 pattern
        'instructions': [
            'Nadechněte na 4 počty',
            'Zadržte na 4 počty', 
            'Vydechněte na 4 počty',
            'Zadržte na 4 počty'
        ],
        'cycles': 2,
        'background_sound': 'gentle_waves',
        'completion_message': 'Breathing complete. Your mind is ready for focused work.'
    }

def get_breathing_exercise(self) -> Dict:
    exercises = [
        {"name": "4-7-8 Dýchání", "duration_minutes": 2, ...},
        {"name": "Krabicové dýchání", "duration_minutes": 3, ...},
        {"name": "Trojité dýchání", "duration_minutes": 1, ...}
    ]
    return random.choice(exercises)
```

**UI Route:** `/breathing-space`

---

### 3. 🌊 **Flow State Detection (Detekce flow stavu)**

**Soubor:** `flow_manager.py`

**Co dělá:**
- **Real-time monitoring** pracovní session
- **Detekce flow stavu** na základě:
  - **Typing rhythm consistency** - konzistence rytmu psaní
  - **Focus duration** - délka nepřerušovaného focusu
  - **Interruption rate** - míra přerušení (na hodinu)
  - **Activity intensity** - intenzita aktivity (posledních 5 minut)

**Algoritmus flow detection:**
```python
flow_score = (
    typing_consistency * 0.3 +
    min(focus_duration / 25, 1.0) * 0.3 +
    max(0, 1.0 - interruption_rate) * 0.2 +
    activity_intensity * 0.2
)

is_in_flow = flow_score >= 0.7  # threshold
```

**Activity tracking:**
```python
class ActivityPattern:
    timestamp: datetime
    activity_type: str  # 'keypress', 'mouse_move', 'app_switch', 'idle'
    intensity: float    # 0.0-1.0
    duration: float     # seconds
```

**Flow State entity:**
```python
class FlowState:
    is_in_flow: bool
    confidence: float        # 0.0-1.0
    flow_duration: int       # minutes
    quality_score: float     # 0.0-1.0
    interruption_count: int
    suggested_action: str    # "continue_flow", "take_break", etc.
```

**Databáze:**
```python
class WorkSession(db.Model):
    flow_detected = db.Column(db.Boolean, default=False)
    flow_start_time = db.Column(db.DateTime)
    flow_duration = db.Column(db.Integer, default=0)  # minutes
    interruption_count = db.Column(db.Integer, default=0)
    focus_quality = db.Column(db.Float, default=0.0)  # 0.0-1.0
    activity_score = db.Column(db.Float, default=0.0)  # typing rhythm
```

---

### 4. ⏱️ **Adaptive Pomodoro+ Timer (Adaptivní časovač)**

**Soubor:** `flow_manager.py` (metoda `suggest_action`)

**Co dělá:**
- **Adaptivní rozhodování** na základě flow stavu:
  - Pokud **v flow** a běží > 25 min → nabídne "Pokračovat" nebo "Přestávka"
  - Pokud **v flow** a < 25 min → "Pokračuj dál"
  - Pokud **mimo flow** a > 25 min → "Čas na přestávku"
  - Pokud **3+ přerušení** → "Změň prostředí"

**Implementace:**
```python
def suggest_action(self, session_id: int) -> Dict:
    flow_state = self.detect_flow_state(session_id)
    session_duration = (utcnow() - session['start_time']).seconds / 60
    
    if flow_state.is_in_flow and session_duration >= 25:
        return {
            'action': 'continue_flow',
            'message': f"You're in flow for {flow_duration} minutes! Continue or break?",
            'options': [
                {'id': 'continue', 'text': 'Keep Going', 'recommended': True},
                {'id': 'extend', 'text': 'Extend +15min'},
                {'id': 'break', 'text': 'Take Break'}
            ]
        }
```

**Suggested actions:**
- `continue_flow` - v flow, běží 25+ min
- `maintain_flow` - v flow, < 25 min
- `take_break` - mimo flow, 25+ min
- `refocus` - 3+ přerušení
- `continue_work` - default

---

### 5. 🏆 **Professional Achievement System (Systém úspěchů)**

**Soubor:** `achievement_system.py`

**Co dělá:**
- **20+ achievements** napříč 6 kategoriemi
- **5 tierů** (Bronze → Silver → Gold → Platinum → Diamond)
- **Prerequisite system** - některé achievementy vyžadují splnění předchozích

**Achievement Categories:**
```python
class AchievementType(Enum):
    DEEP_WORK = "deep_work"
    FLOW_STATE = "flow_state"
    CONSISTENCY = "consistency"
    TASK_COMPLETION = "task_completion"
    LEARNING = "learning"
    PROFESSIONAL_GROWTH = "professional_growth"
```

**Příklady achievementů:**

**Deep Work:**
- `deep_work_novice` - 10h deep work (Bronze, 100 bodů)
- `deep_work_apprentice` - 50h deep work (Silver, 250 bodů)
- `deep_work_master` - 200h deep work (Gold, 500 bodů)
- `deep_work_legend` - 500h deep work (Platinum, 1000 bodů)

**Flow State:**
- `flow_finder` - 5x flow sessions (Bronze, 150 bodů)
- `flow_seeker` - 25x flow sessions (Silver, 300 bodů)
- `flow_master` - 100x flow sessions (Gold, 750 bodů)
- `flow_marathon` - 2h flow v jedné session (Gold, 400 bodů)

**Consistency:**
- `consistency_starter` - 7 denní streak (Bronze, 200 bodů)
- `consistency_champion` - 30 denní streak (Silver, 500 bodů)
- `consistency_legend` - 100 denní streak (Gold, 1000 bodů)

**Task Completion:**
- `task_rookie` - 50 úkolů (Bronze, 100 bodů)
- `task_professional` - 250 úkolů (Silver, 300 bodů)
- `task_expert` - 1000 úkolů (Gold, 750 bodů)
- `complexity_conqueror` - 25 complex tasks (Gold, 600 bodů)

**Learning:**
- `reflection_rookie` - 5 weekly reflections (Bronze, 150 bodů)
- `insight_seeker` - 20 weekly reflections (Silver, 400 bodů)
- `wisdom_keeper` - 52 weekly reflections (Gold, 1000 bodů)

**Professional Growth:**
- `morning_ritualist` - 30 morning intentions (Silver, 350 bodů)
- `ai_collaborator` - 50 AI interactions (Silver, 300 bodů)
- `peak_performer` - 7 dní 95%+ focus quality (Platinum, 800 bodů)

**Rewards:**
```python
class ProfessionalReward:
    id: str
    title: str
    reward_type: str  # 'insight', 'feature', 'customization', 'badge'
    rarity: str       # 'common', 'rare', 'epic', 'legendary'
```

Příklady rewards:
- Advanced Productivity Insights (rare feature)
- Custom Theme Palette (epic customization)
- AI Productivity Coach (legendary feature)
- Flow Mastery Badge (epic badge)
- Productivity Excellence Certificate (legendary insight)

---

### 6. 💪 **Habit Formation Tracking (Sledování návyků)**

**Soubor:** `ai_work_coach.py`

**Co dělá:**
- **Neuroplasticity window** - 21-66 dní pro formování návyků
- **4 fáze** formování návyků:
  - `forming` - 0-6 dní
  - `storming` - 7-20 dní
  - `norming` - 21-65 dní
  - `performing` - 66+ dní (zvládnuto)

**Habit Metrics:**
```python
class HabitMetric:
    habit_name: str
    current_streak: int
    longest_streak: int
    consistency_rate: float     # 0.0-1.0
    strength_score: float       # 0.0-1.0
    neuroplasticity_phase: str  # "forming", "storming", "norming", "performing"
    days_to_automatic: int      # Kolik dní zbývá do 66
```

**Strength score výpočet:**
```python
strength_score = min(1.0, (current_streak / 66) * 0.7 + consistency_rate * 0.3)
```

**Implementace:**
```python
def track_habit_formation(self, user_id: int, habit_name: str, completed: bool) -> HabitMetric:
    # Aktualizuje streak
    if yesterday in completion_dates or streak == 0:
        streak += 1
    else:
        streak = 1
    
    # Vypočítá consistency_rate
    consistency_rate = total_completions / total_attempts
    
    # Určí fázi
    if current_streak >= 66: phase = "performing"
    elif current_streak >= 21: phase = "norming"
    elif current_streak >= 7: phase = "storming"
    else: phase = "forming"
```

**Databáze:**
```python
class UserLearningProfile(db.Model):
    behavioral_patterns = db.Column(JSON)  # Dict s habit tracking data
    
# Struktura habit data:
{
    "habit_morning_ritual": {
        "streak": 12,
        "longest_streak": 15,
        "total_completions": 45,
        "total_attempts": 50,
        "start_date": "2025-01-01T00:00:00",
        "completion_dates": ["2025-01-01", "2025-01-02", ...]
    }
}
```

---

### 7. 🤖 **AI Work Coach (AI pracovní kouč)**

**Soubor:** `ai_work_coach.py`, `routes_ai_coach.py`

**Co dělá:**
- **Context-aware coaching zprávy** v 8 situacích:
  - `MORNING_START` - ranní start
  - `WORK_SESSION` - během práce
  - `BREAK_TIME` - čas na přestávku
  - `FLOW_STATE` - v flow stavu
  - `STRUGGLE_DETECTED` - detekován problém
  - `HABIT_FORMATION` - formování návyků
  - `WEEKLY_REVIEW` - týdenní review
  - `IDENTITY_REINFORCEMENT` - posilování identity

**Coaching Message:**
```python
class CoachingMessage:
    message: str                     # Hlavní zpráva (max 200 znaků)
    context: CoachingContext
    confidence: float                # 0.0-1.0
    timing: str                      # "immediate", "delayed", "scheduled"
    action_suggestions: List[str]    # Konkrétní akce
    neuroplasticity_trigger: str     # Neuroplasticity tip
    identity_reinforcement: str      # Identity-based message
```

**User Identity System:**
```python
class UserIdentity:
    core_identity: str               # "produktivní_profesionál", "tvůrce", "student"
    identity_strength: float         # 0.0-1.0
    identity_keywords: List[str]
    behavior_alignment: float        # 0.0-1.0
    growth_areas: List[str]

# Identity patterns:
"produktivní_profesionál": {
    "keywords": ["efektivní", "organizovaný", "spolehlivý"],
    "behaviors": ["morning_ritual", "deep_work", "priority_management"],
    "reinforcement": "Jako produktivní profesionál máte schopnost..."
}
```

**AI Prompt pro coaching:**
```python
def _create_coaching_prompt(self, context: CoachingContext, user_context: Dict) -> str:
    return f"""
    Jste zkušený AI work coach a mentor pro produktivitu.
    
    KONTEXT: {context.value}
    ČAS DNE: {time_of_day}h
    PRODUKTIVITA: {recent_productivity['trend']}
    ENERGIE: {energy_level}/10
    FLOW SESSIONS DNES: {flow_sessions_today}
    FORMOVÁNÍ NÁVYKŮ: {formation_phase}
    IDENTITA: {core_identity}
    
    POŽADAVKY:
    1. Zpráva v češtině, max 200 znaků
    2. Personalizovaná podle kontextu
    3. Motivační, ale realistická
    4. Zaměřená na neuroplasticitu a identity
    
    FORMÁT:
    [ZPRÁVA]
    [AKCE1|AKCE2|AKCE3]
    [NEUROPLASTICITY_TRIGGER]
    [IDENTITY_REINFORCEMENT]
    """
```

**Route:** `/coach/message` (API endpoint)

---

### 8. 🚨 **Burnout Protection System (Ochrana před vyhořením)**

**Soubor:** `wellness.py`, `routes_wellness.py`

**Co dělá:**
- **4-level risk assessment:**
  - `LOW` (zelená) - vše OK
  - `MODERATE` (žlutá) - střední riziko
  - `HIGH` (oranžová) - vysoké riziko
  - `CRITICAL` (červená) - kritické riziko

**Wellness Metrics:**
```python
class WellnessMetrics:
    tasks_completed: int
    tasks_created: int
    avg_stress_level: float
    avg_energy_level: float
    consecutive_work_days: int
    total_estimated_hours: float
    burnout_risk: BurnoutRisk
    recommendations: List[str]
```

**Risk Thresholds:**
```python
risk_thresholds = {
    'max_tasks_per_day': 15,
    'max_consecutive_days': 7,
    'max_daily_hours': 10,
    'critical_stress_level': 4.0,
    'min_energy_threshold': 2.0
}
```

**Risk Assessment Algorithm:**
```python
def _assess_burnout_risk(self, metrics: Dict) -> BurnoutRisk:
    risk_factors = 0
    
    # High task volume (7 denní období)
    if created_count > max_tasks_per_day * 7:
        risk_factors += 2
    
    # Long work periods
    if total_hours > max_daily_hours * 7:
        risk_factors += 2
    
    # Consecutive work days
    if consecutive_days > max_consecutive_days:
        risk_factors += 2
    
    # High stress
    if avg_stress >= critical_stress_level:
        risk_factors += 3
    
    # Low energy
    if avg_energy <= min_energy_threshold:
        risk_factors += 2
    
    # Určení rizika
    if risk_factors >= 6: return BurnoutRisk.CRITICAL
    elif risk_factors >= 4: return BurnoutRisk.HIGH
    elif risk_factors >= 2: return BurnoutRisk.MODERATE
    else: return BurnoutRisk.LOW
```

**Recommendations by Risk Level:**

**CRITICAL:**
- 🚨 KRITICKÉ: Doporučujeme okamžitou pauzu!
- 📞 Zvažte konzultaci s odborníkem na duševní zdraví
- 🛌 Naplánujte si minimálně 2 dny odpočinku
- 🧘 Praktikujte relaxační techniky a meditaci

**HIGH:**
- ⚠️ Vysoké riziko vyhoření - snižte pracovní zátěž
- 🌅 Naplánujte si delší přestávky mezi úkoly
- 🚶 Přidejte pohyb a procházky do denního programu
- 😴 Zajistěte si dostatečný spánek (7-9 hodin)

**MODERATE:**
- 💡 Střední riziko - věnujte pozornost work-life balance
- ⏰ Nastavte si časové limity pro práci
- 🎯 Soustřeďte se na 3-5 prioritních úkolů denně

**LOW:**
- ✅ Výborná práce s udržováním rovnováhy!
- 🎉 Pokračujte v současném tempu
- 💪 Nezapomínejte na pravidelné přestávky

**Route:** `/wellness` (dashboard s metrikami)

---

### 9. 📊 **Productivity Metrics Dashboard (Dashboard metrik)**

**Soubor:** `analytics_service.py`, `routes_analytics.py`

**Co dělá:**
- **Comprehensive analytics** za období (7-365 dní)
- **4 hlavní kategorie metrik:**

**1. Deep Work Analytics:**
```python
{
    'total_hours': 45.5,
    'avg_daily_hours': 6.5,
    'best_day_hours': 8.2,
    'avg_quality': 0.85,
    'consistency_rate': 0.92,
    'working_days': 7,
    'trend': 'up',  # 'up', 'down', 'stable'
    'change_percentage': 15.3,
    'weekly_pattern': {...},
    'quality_trend': [...]
}
```

**2. Flow State Analytics:**
```python
{
    'total_flow_sessions': 12,
    'flow_rate': 0.75,
    'total_flow_time': 360.0,  # minutes
    'avg_flow_duration': 30.0,
    'best_flow_duration': 120.0,
    'avg_flow_quality': 0.88,
    'flow_triggers': {
        'time_of_day': {'morning': 5, 'afternoon': 7},
        'session_type': {'pomodoro': 8, 'flow': 4},
        'day_of_week': {'Monday': 3, 'Tuesday': 4, ...}
    },
    'flow_pattern': {...}
}
```

**3. Task Completion Analytics:**
```python
{
    'total_completed': 45,
    'completion_rate': 0.82,
    'avg_complexity': 3.2,
    'complexity_distribution': {
        'simple': 15,    # difficulty_perception = 'easy'
        'moderate': 20,  # 'challenging'
        'complex': 10    # 'overwhelming'
    },
    'priority_distribution': {
        'A': 12, 'B': 20, 'C': 10, 'D': 3, 'None': 0
    },
    'avg_completion_time': 48.0,  # hours
    'daily_completion_pattern': {...}
}
```

**4. Consistency Analytics:**
```python
{
    'intention_consistency': 0.85,
    'session_consistency': 0.92,
    'current_streak': 14,
    'longest_streak': 21,
    'weekly_pattern': {...},
    'consistency_score': 0.88
}
```

**Professional Insights:**
```python
class ProfessionalInsight:
    category: str
    insight: str
    recommendation: str
    impact_level: str  # 'high', 'medium', 'low'
    confidence: float

# Příklad insight:
{
    'category': 'deep_work',
    'insight': 'Excellent deep work discipline with 6.5 hours daily average',
    'recommendation': 'Maintain this exceptional pace. Consider sharing strategies.',
    'impact_level': 'high',
    'confidence': 0.9
}
```

**Route:** `/analytics/dashboard`

---

### 10. 🎯 **AI-Powered Priority Management (AI řízení priorit)**

**Soubor:** `routes_priorities.py`, `models_user.py`

**Co dělá:**
- **8 kategorií úkolů** s AI klasifikací:
  - `family` (rodina)
  - `work` (práce)
  - `hobbies` (záliby)
  - `health` (zdraví)
  - `personal` (osobní)
  - `shopping` (nákupy)
  - `learning` (učení)
  - `other` (ostatní)

**UserPriorities Model:**
```python
class UserPriorities(db.Model):
    # Priority ordering (1=highest, 8=lowest)
    family_priority = db.Column(db.Integer, default=1)
    work_priority = db.Column(db.Integer, default=2)
    hobbies_priority = db.Column(db.Integer, default=3)
    health_priority = db.Column(db.Integer, default=4)
    personal_priority = db.Column(db.Integer, default=5)
    shopping_priority = db.Column(db.Integer, default=6)
    learning_priority = db.Column(db.Integer, default=7)
    other_priority = db.Column(db.Integer, default=8)
    
    # AI weights (0.0-1.0)
    ai_weight_family = db.Column(db.Float, default=1.0)
    ai_weight_work = db.Column(db.Float, default=0.8)
    # ... pro každou kategorii
    
    # Best time for each category
    family_best_time = db.Column(db.String(20), default="evening")
    work_best_time = db.Column(db.String(20), default="morning")
    # ... pro každou kategorii
```

**AI Task Categorization:**
```python
def categorize_task(self, task_text: str, context: str = None) -> Dict:
    # AI analyzuje text úkolu a vrací:
    {
        "category": "family",
        "confidence": 0.85,
        "keywords": ["manželka", "děti", "návštěva"],
        "reasoning": "Úkol se týká rodinných aktivit a vztahů"
    }
```

**Recommendation Algorithm:**
```python
def generate_ai_recommendations(categorized_tasks, user_priorities, settings):
    for task in tasks:
        # 1. Base score z category priority (1=80, 2=70, ...)
        base_score = (9 - category_priority) * 10
        
        # 2. AI weight multiplier
        weighted_score = base_score * category_weight
        
        # 3. Time context bonus (15 bodů pokud ideální čas)
        if best_time matches current_hour:
            weighted_score += 15
        
        # 4. Overdue boost (20 bodů)
        if task.is_overdue():
            weighted_score += 20
        
        # 5. Priority boost (A=30, B=20, C=10)
        weighted_score += priority_boost
        
        # 6. AI confidence factor
        final_score = weighted_score * (0.5 + confidence * 0.5)
    
    # Seřadit podle final_score (sestupně)
    # Vrátit top N úkolů (default 100)
```

**Category-Specific Motivational Prompts:**

Každá kategorie má **vlastní AI prompt** pro motivační zprávy:

```python
# Rodina:
"Jsi rodinný kouč a podporovatel. Motivuj k rodinnému úkolu.
STYL: Teplý, laskavý, zaměřený na vztahy a lásku
FOKUS: Hodnoty rodiny, společné chvíle, péče o blízké"

# Práce:
"Jsi kariérní kouč a mentor. Motivuj k pracovnímu úkolu.
STYL: Profesionální, motivující, zaměřený na úspěch
FOKUS: Kariérní růst, produktivita, dosažení cílů"

# ... pro každou kategorii
```

**Routes:**
- `/priorities` - Dashboard s AI doporučeními
- `/priorities/settings` - Nastavení priorit a weights
- `/api/categorize_task` - API pro AI kategorizaci
- `/api/motivational_message` - API pro motivační zprávy

---

### 11. 🌳 **Hierarchical Tasks (Hierarchické úkoly)**

**Soubor:** `models.py` (Todo model)

**Co dělá:**
- **Parent-child relationships** - úkoly mohou mít podúkoly
- **Depth level calculation** - automatický výpočet hloubky
- **Recursive progress tracking** - progress celého stromu

**Model fields:**
```python
class Todo(db.Model):
    # Hierarchical structure
    parent_id = db.Column(db.Integer, db.ForeignKey('todos.id'))
    parent = db.relationship('Todo', remote_side=[id], 
                           backref=db.backref('children', cascade='all, delete-orphan'))
    indent_level = db.Column(db.Integer, default=0)
    depth_level = db.Column(db.Integer, default=0)  # 0=root, 1=child, 2=grandchild
    project_phase = db.Column(db.String(50))  # "planning", "execution", "review"
```

**Depth calculation:**
```python
def calculate_depth_level(self):
    if not self.parent_id:
        return 0
    
    depth = 0
    current = self
    while current.parent_id:
        depth += 1
        current = current.parent
        if depth > 10:  # Safety check
            break
    return depth
```

**Project progress:**
```python
def get_project_progress(self) -> dict:
    total = len(self.children)
    completed = sum(1 for child in self.children if child.completed)
    percentage = (completed / total * 100) if total > 0 else 0
    
    return {
        'total': total,
        'completed': completed,
        'percentage': round(percentage, 1),
        'remaining': total - completed
    }
```

**Recursive counts:**
```python
def get_all_descendants_count(self) -> int:
    count = 0
    for child in self.children:
        count += 1 + child.get_all_descendants_count()
    return count
```

---

### 12. 📋 **Org-mode Style Metadata (@key(value))**

**Soubor:** `models.py`, `routes_org.py`

**Co dělá:**
- **Flexible metadata** v textu úkolu
- **@key(value) syntax** - org-mode inspirovaná
- **Parsing a storage** - automatické parsování z textu

**Příklad:**
```
Zavolat klientovi @telefon(+420123456789) @doba(15min) @nalada(dobra)
```

**Model fields:**
```python
class Todo(db.Model):
    org_metadata = db.Column(JSON)  # {"telefon": "+420...", "doba": "15min", "nalada": "dobra"}
```

**Metody:**
```python
def set_org_metadata(self, key: str, value: str):
    if not self.org_metadata:
        self.org_metadata = {}
    self.org_metadata[key] = value

def get_org_metadata(self, key: str, default=None):
    if not self.org_metadata:
        return default
    return self.org_metadata.get(key, default)

def parse_org_metadata_text(self, text: str):
    pattern = r'@(\w+)\(([^)]+)\)'
    matches = re.findall(pattern, text)
    
    for key, value in matches:
        self.org_metadata[key] = value
    
    # Return text without metadata
    return re.sub(pattern, '', text).strip()

def get_formatted_metadata(self) -> str:
    parts = []
    for key, value in self.org_metadata.items():
        parts.append(f"@{key}({value})")
    return " ".join(parts)
```

**Route:** `/org/metadata` - UI pro správu metadat

---

### 13. 🔢 **Todo.txt Style Sequential Numbering**

**Soubor:** `models.py`

**Co dělá:**
- **Globální sekvenční číslování** všech úkolů
- **Unique numbers** - každý úkol má unikátní číslo

**Model field:**
```python
class Todo(db.Model):
    todo_number = db.Column(db.Integer, unique=True)  # Global sequential
```

**Assignment:**
```python
@classmethod
def assign_next_todo_number(cls):
    max_number = db.session.query(db.func.max(cls.todo_number)).scalar()
    return (max_number or 0) + 1

# Při vytváření:
todo = Todo(
    text=clean_text,
    todo_number=Todo.assign_next_todo_number(),
    ...
)
```

**Zobrazení:**
```
#1 Zavolat klientovi
#2 Dokončit prezentaci
#3 Nakoupit potraviny
```

---

### 14. 🧠 **Czech Natural Language Parser**

**Soubor:** `czech_parser.py`

**Co dělá:**
- **Automatické parsování** českého textu úkolu
- **Extrakce metadat** bez nutnosti strukturovaného vstupu
- **Confidence scoring** - jak si je parser jistý

**CzechTaskParser:**
```python
class CzechTaskParser:
    def parse_task(self, text: str) -> Dict:
        result = {
            'original_text': text,
            'cleaned_text': text,
            'priority': None,        # A-D
            'due_date': None,        # YYYY-MM-DD
            'context': None,         # work/personal/projects
            'effort': None,          # 15min, 30min, 1h, ...
            'emotions': [],          # [stress, excitement, ...]
            'difficulty': None,      # easy/challenging/overwhelming
            'confidence': 0.0        # 0.0-1.0
        }
```

**Priority patterns:**
```python
priority_patterns = {
    'A': [
        r'\b(urgentní|urgentně|naléhavé|kritické|okamžitě|hned|ihned|asap)\b',
        r'\b(důležité|důležitý|prioritní|priorita)\b',
        r'\b(musí|musím|muset)\b.*\b(dnes|teď|nyní)\b',
        r'[!]{2,}',  # Multiple exclamation marks
    ],
    'B': [
        r'\b(brzy|brzo|rychle|v brzké době|co nejdříve)\b',
        r'[!]{1}',  # Single exclamation mark
    ],
    # ... C, D
}
```

**Time patterns:**
```python
time_patterns = {
    'today': [
        r'\b(dnes|dneska|ještě dnes|do večera)\b',
        r'\b(do \d{1,2}:\d{2})\b',  # do 15:30
    ],
    'tomorrow': [r'\b(zítra|zítřek|do zítra)\b'],
    'this_week': [r'\b(tento týden|do konce týdne|do pátku)\b'],
    'specific_date': [
        r'\b(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4}|\d{2})?\b',  # 15.3.2024
    ]
}
```

**Context patterns:**
```python
context_patterns = {
    'work': [
        r'\b(v práci|v kanceláři|na pracovišti|do práce|pracovní)\b',
        r'\b(meeting|schůzka|porada|prezentace|projekt)\b',
        r'\b(email|mail|telefon|hovor|prezentovat)\b',
        r'\b(naložit|přeložit|přenést|postavit|stavba)\b',
    ],
    'personal': [
        r'\b(doma|domů|domácí|osobní|soukromé)\b',
        r'\b(nákup|nakoupit|obchod|potraviny)\b',
    ],
    # ... projects
}
```

**Emotion patterns:**
```python
emotion_patterns = {
    'stress': [
        r'\b(stres|stresující|nervózní|úzkost|tlak)\b',
        r'\b(musím|nesmím zapomenout|deadline|termín)\b'
    ],
    'excitement': [r'\b(těším se|nadšení|skvělé|úžasné|cool)\b'],
    'guilt': [
        r'\b(měl jsem|měla jsem|zapomněl|zapomněla)\b',
        r'\b(už dávno|odkládám|prokrastinuji)\b'
    ],
    'care': [r'\b(milovaný|milovaná|důležité pro|záleží mi)\b']
}
```

**Effort patterns:**
```python
effort_patterns = {
    '15min': [r'\b(rychle|rychlý|chvilka|moment|minutka)\b'],
    '30min': [r'\b(chvíli|půl hodiny|30\s*min)\b'],
    '1h': [r'\b(hodinu|1\s*h|60\s*min)\b'],
    '2h': [r'\b(dlouho|dlouhý|2\s*h|dva hodiny)\b'],
    '4h': [r'\b(velmi dlouho|půl dne|4\s*h|celé odpoledne)\b']
}
```

**Příklad použití:**
```python
parser = CzechTaskParser()
result = parser.parse_task("Urgentně dokončit prezentaci do zítra v práci!")

# Result:
{
    'original_text': 'Urgentně dokončit prezentaci do zítra v práci!',
    'cleaned_text': 'Dokončit prezentaci',
    'priority': 'A',
    'due_date': '2025-10-17',
    'context': 'work',
    'effort': '2h',
    'emotions': ['stress'],
    'difficulty': 'challenging',
    'confidence': 0.85
}
```

---

### 15. 📈 **Weekly Reflection System (Týdenní reflexe)**

**Soubor:** `routes_analytics.py`

**Co dělá:**
- **Guided weekly review** s AI doporučeními
- **Reflection questions** na základě výkonu
- **Learning capture** - co jsem se naučil

**Reflection Questions Generation:**
```python
def generate_reflection_questions(weekly_data: dict) -> List[Dict]:
    questions = []
    
    # Deep work reflection
    if deep_work['avg_daily_hours'] >= 4:
        questions.append({
            'category': 'deep_work',
            'question': 'What strategies helped you achieve such strong deep work this week?',
            'type': 'text'
        })
    else:
        questions.append({
            'category': 'deep_work',
            'question': 'What barriers prevented you from achieving more deep work this week?',
            'type': 'text'
        })
    
    # Flow state reflection
    if flow_rate >= 0.5:
        questions.append({
            'category': 'flow',
            'question': 'Which conditions or activities triggered your flow states most effectively?',
            'type': 'text'
        })
    
    # Consistency reflection
    questions.append({
        'category': 'consistency',
        'question': f'You maintained a {consistency_score:.0%} consistency rate. What would help you be more consistent?',
        'type': 'text'
    })
    
    # General reflection
    questions.append({'question': 'What was your biggest win this week?'})
    questions.append({'question': 'What would you do differently next week?'})
    
    return questions
```

**Storage:**
```python
class DailyIntention(db.Model):
    evening_reflection = db.Column(db.Text)
    satisfaction_rating = db.Column(db.Integer)  # 1-10
    lessons_learned = db.Column(db.Text)
```

**Route:** `/analytics/weekly_reflection`

---

## 📊 DATABÁZOVÉ MODELY CO NEMÁME

### WorkSession (Pracovní session)
```python
class WorkSession(db.Model):
    user_id = db.Column(db.Integer)
    task_id = db.Column(db.Integer, db.ForeignKey('todos.id'))
    
    # Session timing
    start_time = db.Column(db.DateTime)
    end_time = db.Column(db.DateTime)
    planned_duration = db.Column(db.Integer, default=25)  # minutes
    actual_duration = db.Column(db.Integer)
    
    # Session type
    session_type = db.Column(db.String(20), default='pomodoro')
    session_state = db.Column(db.String(20), default='active')
    
    # Flow detection
    flow_detected = db.Column(db.Boolean, default=False)
    flow_start_time = db.Column(db.DateTime)
    flow_duration = db.Column(db.Integer, default=0)  # minutes
    
    # Quality metrics
    interruption_count = db.Column(db.Integer, default=0)
    focus_quality = db.Column(db.Float, default=0.0)  # 0.0-1.0
    activity_score = db.Column(db.Float, default=0.0)
    
    # Completion
    tasks_completed = db.Column(db.Integer, default=0)
    complexity_handled = db.Column(db.Float, default=0.0)
```

### DailyIntention (Denní záměr)
```python
class DailyIntention(db.Model):
    user_id = db.Column(db.Integer)
    date = db.Column(db.Date, default=date.today)
    
    # Intention setting
    primary_goal = db.Column(db.Text, nullable=False)
    primary_task_id = db.Column(db.Integer, db.ForeignKey('todos.id'))
    secondary_goals = db.Column(JSON, default=list)
    
    # Energy and capacity
    energy_level = db.Column(db.Integer, nullable=False)  # 1-10
    expected_hours = db.Column(db.Float, nullable=False)  # 0.5-12.0
    energy_type = db.Column(db.String(20), default='balanced')
    
    # Context
    work_context = db.Column(db.String(50))  # 'home', 'office', 'mobile'
    mood_rating = db.Column(db.Integer)  # 1-10
    stress_level = db.Column(db.Integer)  # 1-10
    
    # AI suggestions
    ai_suggestions = db.Column(JSON, default=list)
    ai_task_breakdown = db.Column(JSON, default=dict)
    
    # Progress tracking
    completed = db.Column(db.Boolean, default=False)
    completion_percentage = db.Column(db.Float, default=0.0)
    actual_hours_worked = db.Column(db.Float, default=0.0)
    
    # Reflection
    evening_reflection = db.Column(db.Text)
    satisfaction_rating = db.Column(db.Integer)  # 1-10
    lessons_learned = db.Column(db.Text)
```

### ProductivityMetrics (Metriky produktivity)
```python
class ProductivityMetrics(db.Model):
    user_id = db.Column(db.Integer)
    date = db.Column(db.Date, default=date.today)
    
    # Core metrics
    deep_work_hours = db.Column(db.Float, default=0.0)
    flow_sessions = db.Column(db.Integer, default=0)
    total_flow_time = db.Column(db.Float, default=0.0)  # minutes
    average_flow_duration = db.Column(db.Float, default=0.0)
    
    # Task metrics
    tasks_completed = db.Column(db.Integer, default=0)
    tasks_started = db.Column(db.Integer, default=0)
    completion_rate = db.Column(db.Float, default=0.0)  # percentage
    
    # Complexity metrics
    simple_tasks = db.Column(db.Integer, default=0)
    moderate_tasks = db.Column(db.Integer, default=0)
    complex_tasks = db.Column(db.Integer, default=0)
    complexity_score = db.Column(db.Float, default=0.0)
    
    # Consistency metrics
    work_sessions = db.Column(db.Integer, default=0)
    session_consistency = db.Column(db.Float, default=0.0)
    daily_streak = db.Column(db.Integer, default=0)
    consistency_index = db.Column(db.Float, default=0.0)
    
    # AI collaboration
    ai_suggestions_used = db.Column(db.Integer, default=0)
    ai_task_breakdowns = db.Column(db.Integer, default=0)
    ai_coaching_interactions = db.Column(db.Integer, default=0)
    ai_collaboration_rate = db.Column(db.Float, default=0.0)
    
    # Quality metrics
    average_focus_quality = db.Column(db.Float, default=0.0)
    interruption_rate = db.Column(db.Float, default=0.0)  # per hour
    distraction_resistance = db.Column(db.Float, default=0.0)
```

### UserPriorities (Uživatelské priority)
```python
class UserPriorities(db.Model):
    # Priority ordering (1=highest, 8=lowest)
    family_priority = db.Column(db.Integer, default=1)
    work_priority = db.Column(db.Integer, default=2)
    hobbies_priority = db.Column(db.Integer, default=3)
    health_priority = db.Column(db.Integer, default=4)
    personal_priority = db.Column(db.Integer, default=5)
    shopping_priority = db.Column(db.Integer, default=6)
    learning_priority = db.Column(db.Integer, default=7)
    other_priority = db.Column(db.Integer, default=8)
    
    # AI weights (0.0-1.0)
    ai_weight_family = db.Column(db.Float, default=1.0)
    ai_weight_work = db.Column(db.Float, default=0.8)
    # ... for each category
    
    # Best time preferences
    family_best_time = db.Column(db.String(20), default="evening")
    work_best_time = db.Column(db.String(20), default="morning")
    # ... for each category
```

### UserLearningProfile (Učící se profil)
```python
class UserLearningProfile(db.Model):
    user_id = db.Column(db.Integer, default=1)
    
    # Learning data (JSON)
    style_preferences = db.Column(JSON)
    completion_patterns = db.Column(JSON)
    completion_rate_accuracy = db.Column(db.Float, default=0.0)
    optimal_timing = db.Column(JSON)
    energy_patterns = db.Column(JSON)
    
    # Burnout tracking
    stress_indicators_count = db.Column(db.Integer, default=0)
    recent_completion_trend = db.Column(db.String(20), default='stable')
    
    # Task preferences
    preferred_task_breakdown = db.Column(db.String(50))
    preferred_context_batch = db.Column(JSON)
    
    # Behavioral patterns (habit tracking)
    behavioral_patterns = db.Column(JSON)
```

---

## 🔧 ROZŠÍŘENÍ TODO MODELU

Python aplikace má v Todo modelu následující pole navíc:

```python
class Todo(db.Model):
    # Todo.txt style numbering
    todo_number = db.Column(db.Integer, unique=True)
    
    # Hierarchical structure
    parent_id = db.Column(db.Integer, db.ForeignKey('todos.id'))
    indent_level = db.Column(db.Integer, default=0)
    depth_level = db.Column(db.Integer, default=0)
    project_phase = db.Column(db.String(50))  # planning/execution/review
    
    # Org-mode metadata
    org_metadata = db.Column(JSON)  # @key(value) syntax
    
    # AI enhancement
    ai_estimated_duration = db.Column(db.Integer)  # minutes
    ai_suggested_energy = db.Column(db.Integer)  # 1-10
    ai_dependencies = db.Column(JSON)  # [task_id1, task_id2]
    ai_risk_level = db.Column(db.String(20))  # low/medium/high
    ai_context_suggestions = db.Column(JSON)  # ["morning", "high_energy"]
    
    # Task categorization
    ai_predicted_category = db.Column(db.String(20))  # family/work/hobbies/...
    ai_category_confidence = db.Column(db.Float)  # 0.0-1.0
    manual_category = db.Column(db.String(20))  # User override
    category_keywords = db.Column(JSON)  # Keywords used for categorization
    
    # Metody:
    def difficulty_perception_numeric(self) -> int  # 1-5
    def is_overdue(self) -> bool
    def days_until_due(self) -> int
    def calculate_depth_level(self) -> int
    def get_project_progress(self) -> dict
    def get_ai_recommendations(self) -> dict
    def get_effective_category(self) -> str
    def set_ai_category(category, confidence, keywords)
    def get_category_info(self) -> dict
    def parse_org_metadata_text(text: str)
    def get_formatted_metadata(self) -> str
```

---

## 📝 ZÁVĚR

Python TODO aplikace obsahuje **komplexní systém pro podporu produktivity** založený na vědeckých principech:

1. **Neuroplasticity** - 21-66 denní okno pro formování návyků
2. **Flow State Science** - detekce a optimalizace flow stavů
3. **Burnout Prevention** - 4-level risk assessment
4. **Identity-Based Habits** - posilování identity skrze chování
5. **AI Coaching** - context-aware personalizované vedení
6. **Professional Gamification** - achievement systém pro dospělé

**Hlavní přínos oproti Flutter aplikaci:**
- Systematický přístup k prevenci prokrastinace
- Vědecky podložené metody formování návyků
- Pokročilá analytika produktivity
- AI-powered prioritizace a kategorizace
- Burnout protection systém

**Doporučení pro implementaci:**
1. Začít s **Morning Ritual System** (nejjednodušší)
2. Přidat **Burnout Protection** (důležité pro well-being)
3. Implementovat **AI Task Categorization** (využije stávající AI Brief)
4. Vybudovat **Flow State Detection** (vyžaduje activity tracking)
5. Nakonec **Achievement System** (komplexní, ale motivující)

---

**Poznámka:** Tento dokument byl vytvořen analýzou zdrojového kódu Python TODO aplikace. Všechny funkce jsou skutečně implementované a funkční.