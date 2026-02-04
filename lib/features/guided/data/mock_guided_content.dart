import '../domain/entities/guided_session.dart';

/// Mock content for guided plans (YouVersion-style).
/// Backend-ready: Replace with API calls when ready.
class MockGuidedPlans {
  static List<GuidedPlan> getAll() => [
    ...getFeatured(),
    ...getScripturePlans().skip(1),
    ...getPrayerPlans().skip(1),
    ...getWorshipPlans().skip(1),
    ...getBreathingPlans().skip(1),
  ];

  static List<GuidedPlan> getFeatured() => [
    _psalm23Plan,
    _morningPrayerPlan,
    _worshipPlan,
    _calmBreathingPlan,
  ];

  static List<GuidedPlan> getScripturePlans() => [
    _psalm23Plan,
    _beatitudesPlan,
    _lordsPrayerPlan,
  ];

  static List<GuidedPlan> getPrayerPlans() => [
    _morningPrayerPlan,
    _eveningExamenPlan,
    _gratitudePlan,
  ];

  static List<GuidedPlan> getWorshipPlans() => [
    _worshipPlan,
    _praisePlan,
  ];

  static List<GuidedPlan> getBreathingPlans() => [
    _calmBreathingPlan,
    _breathPrayerPlan,
  ];

  static List<GuidedPlan> getByType(GuidedContentType type) {
    return getAll().where((p) => p.type == type).toList();
  }

  // ============================================================================
  // SCRIPTURE PLANS
  // ============================================================================

  static final _psalm23Plan = GuidedPlan(
    id: 'psalm-23-journey',
    title: 'The Shepherd\'s Care',
    subtitle: 'A Journey Through Psalm 23',
    description: 'Experience the timeless comfort of Psalm 23. Over 5 days, meditate on God\'s provision, guidance, and eternal love as your Shepherd.',
    type: GuidedContentType.scripturePlan,
    totalDays: 5,
    completedDays: 2,
    imageGradientStart: '#6366F1',
    imageGradientEnd: '#8B5CF6',
    tags: ['psalms', 'peace', 'trust', 'comfort'],
    days: [
      PlanDay(
        dayNumber: 1,
        title: 'The Lord is My Shepherd',
        isCompleted: true,
        content: ScriptureContent(
          reference: 'Psalm 23:1',
          scriptureText: 'The LORD is my shepherd; I shall not want.',
          reflection: '''Today we begin with the most powerful declaration of faith: "The Lord is my shepherd." This single statement transforms everything.

A shepherd in ancient times was responsible for every aspect of his flock's wellbeing. He led them to food and water, protected them from predators, and knew each sheep by name.

When David wrote these words, he drew from his own experience as a shepherd boy. He understood the intimate care a good shepherd provides.

Consider what it means for the Creator of the universe to be YOUR shepherd:

He knows you completely. He provides for your needs. He protects you from harm. He guides your path.

"I shall not want" doesn't mean we'll never desire anything. It means that with God as our shepherd, we have everything we truly need.''',
          prayer: 'Lord, I declare today that You are my Shepherd. Help me to trust in Your provision and care. When I feel lacking, remind me that in You, I have everything I need. Thank You for knowing me, loving me, and guiding me. Amen.',
        ),
      ),
      PlanDay(
        dayNumber: 2,
        title: 'Green Pastures & Still Waters',
        isCompleted: true,
        content: ScriptureContent(
          reference: 'Psalm 23:2',
          scriptureText: 'He makes me lie down in green pastures; He leads me beside still waters.',
          reflection: '''Notice the tenderness in these words. God doesn't force us - He "makes" us lie down, like a loving parent who knows when their child needs rest.

Green pastures represent abundance and nourishment. Still waters speak of peace and refreshment. In the arid Middle East, finding both was a shepherd's greatest achievement for his flock.

Sometimes we resist rest. We push ourselves until we're exhausted, anxious, and depleted. But our Shepherd knows better. He leads us to places of restoration - not as punishment, but as love.

Today, consider: Where is God inviting you to rest? What "green pastures" has He provided that you've overlooked? How might you drink from His "still waters" today?

Rest is not laziness. It's obedience to a Shepherd who knows what we need.''',
          prayer: 'Good Shepherd, forgive me for resisting the rest You offer. Lead me today to Your green pastures. Help me drink deeply from Your still waters. Restore my soul in Your presence. Amen.',
        ),
      ),
      PlanDay(
        dayNumber: 3,
        title: 'Restoration & Righteousness',
        content: ScriptureContent(
          reference: 'Psalm 23:3',
          scriptureText: 'He restores my soul; He leads me in paths of righteousness for His name\'s sake.',
          reflection: '''The Hebrew word for "restore" here means to bring back, to return to the original state. When life depletes us, when we wander, when we're broken - God restores.

He doesn't just patch us up. He restores our souls to the fullness of what He created us to be.

And notice WHY He does this: "for His name's sake." God's reputation is tied to how He cares for His sheep. When we flourish, it reflects His goodness. When we're restored, it demonstrates His faithfulness.

The "paths of righteousness" aren't about perfection. They're about direction. A righteous path is simply the right path - God's path for your life.

You don't have to figure it all out. You just have to follow the Shepherd, one step at a time.''',
          prayer: 'Restorer of my soul, I bring You my weariness, my wandering, my brokenness today. Restore me. Lead me on Your paths - not because I deserve it, but for Your name\'s sake. I trust Your direction. Amen.',
        ),
      ),
      PlanDay(
        dayNumber: 4,
        title: 'Through the Valley',
        content: ScriptureContent(
          reference: 'Psalm 23:4',
          scriptureText: 'Even though I walk through the valley of the shadow of death, I will fear no evil, for You are with me; Your rod and Your staff, they comfort me.',
          reflection: '''This is the verse we cling to in our darkest moments. Notice: we walk THROUGH the valley, not into it and back out. The path goes all the way through.

The "shadow of death" represents our deepest fears - loss, failure, rejection, actual death. But David says even there, "I will fear no evil." Not because the valley isn't real or dangerous, but because "You are with me."

The Shepherd's rod was a weapon for protection. The staff was a tool for guidance and rescue. Both bring comfort because they represent His presence and power.

In your valley today: The Shepherd is WITH you (not watching from afar). His rod protects you from real dangers. His staff guides and rescues when you stumble.

You're not alone in the dark.''',
          prayer: 'Lord, I\'m walking through a valley right now. I choose not to fear because You are with me. I feel Your rod of protection and Your staff of guidance. Even here, especially here, You comfort me. Amen.',
        ),
      ),
      PlanDay(
        dayNumber: 5,
        title: 'Abundance & Forever',
        content: ScriptureContent(
          reference: 'Psalm 23:5-6',
          scriptureText: 'You prepare a table before me in the presence of my enemies; You anoint my head with oil; my cup overflows. Surely goodness and mercy shall follow me all the days of my life, and I shall dwell in the house of the LORD forever.',
          reflection: '''What a triumphant ending! From sheep language, David shifts to feast language. We're no longer just surviving - we're celebrating.

God prepares a table "in the presence of enemies." Not after they're defeated, but while they watch. This is the ultimate statement of God's protection and favor.

Anointing with oil was a sign of honor and blessing. An overflowing cup represents abundance beyond measure. This is God's heart for you.

And the promise: goodness and mercy FOLLOW you. Like two faithful friends, they pursue you. You don't have to chase blessing - it chases you.

Finally, the eternal hope: "I shall dwell in the house of the LORD forever." The journey with the Shepherd doesn't end. It continues into eternity.''',
          prayer: 'Lord, I receive Your abundance today. Thank You for preparing a table for me, for anointing me, for the overflowing cup of Your blessing. I trust that goodness and mercy follow me. And I look forward to dwelling in Your house forever. You are my Shepherd. Amen.',
        ),
      ),
    ],
  );

  static final _beatitudesPlan = GuidedPlan(
    id: 'beatitudes-blessing',
    title: 'The Blessed Life',
    subtitle: 'Jesus\' Beatitudes',
    description: 'Discover the upside-down kingdom values Jesus taught. These 7 days will transform how you see blessing, happiness, and the good life.',
    type: GuidedContentType.scripturePlan,
    totalDays: 7,
    completedDays: 0,
    imageGradientStart: '#8B5CF6',
    imageGradientEnd: '#A855F7',
    tags: ['jesus', 'sermon', 'blessing', 'teaching'],
    days: [],
  );

  static final _lordsPrayerPlan = GuidedPlan(
    id: 'lords-prayer-deep',
    title: 'Teach Us to Pray',
    subtitle: 'The Lord\'s Prayer',
    description: 'Go deeper into the prayer Jesus taught His disciples. Each phrase contains profound truth for your prayer life.',
    type: GuidedContentType.scripturePlan,
    totalDays: 6,
    completedDays: 0,
    imageGradientStart: '#3B82F6',
    imageGradientEnd: '#6366F1',
    tags: ['prayer', 'jesus', 'teaching'],
    days: [],
  );

  // ============================================================================
  // PRAYER PLANS
  // ============================================================================

  static final _morningPrayerPlan = GuidedPlan(
    id: 'morning-offering',
    title: 'Morning Offering',
    subtitle: 'Start Your Day with God',
    description: 'A beautiful 5-minute prayer to dedicate your day to the Lord. Perfect for establishing a morning prayer habit.',
    type: GuidedContentType.guidedPrayer,
    totalDays: 1,
    completedDays: 0,
    imageGradientStart: '#EC4899',
    imageGradientEnd: '#F472B6',
    tags: ['morning', 'daily', 'dedication'],
    days: [
      PlanDay(
        dayNumber: 1,
        title: 'Morning Offering',
        content: PrayerContent(
          introduction: '''Take a deep breath. Feel your feet on the ground. As a new day begins, you have the beautiful opportunity to offer it to God.

This prayer will guide you through dedicating your day - your time, your work, your relationships, your challenges - to the Lord.

When you're ready, pray along with these words, making them your own.''',
          sections: [
            PrayerSection(
              title: 'Gratitude for a New Day',
              content: '''Lord, thank You for this new day.
Thank You that Your mercies are new every morning.
I didn't earn this day - it's a gift from You.

I'm grateful for the breath in my lungs,
the rest I received, and the chance to begin again.

Before I do anything else, I pause to say: Thank You.''',
            ),
            PrayerSection(
              title: 'Surrendering the Day',
              content: '''Father, I offer You this day.
Every hour, every minute, every moment - I give it to You.

I surrender my plans to Your will.
I surrender my agenda to Your purposes.
I surrender my expectations to Your wisdom.

Whatever comes today, I trust it passes through Your loving hands first.

Use me today. Work through me today.
Let my life bring You glory.''',
            ),
            PrayerSection(
              title: 'Strength for What Lies Ahead',
              content: '''Holy Spirit, I need You today.
I don't know everything this day holds, but You do.

Give me strength for the challenges.
Give me wisdom for the decisions.
Give me patience for the difficulties.
Give me love for the people I'll encounter.

Fill me fresh today with Your presence.''',
            ),
          ],
          closingPrayer: '''Father, Son, and Holy Spirit,
I am Yours and this day is Yours.
Do with me what You will.
I trust You completely.

In Jesus' name, Amen.''',
        ),
      ),
    ],
  );

  static final _eveningExamenPlan = GuidedPlan(
    id: 'evening-examen',
    title: 'Daily Examen',
    subtitle: 'Evening Reflection',
    description: 'An ancient prayer practice to review your day with God. Notice His presence and prepare your heart for rest.',
    type: GuidedContentType.guidedPrayer,
    totalDays: 1,
    completedDays: 0,
    imageGradientStart: '#7C3AED',
    imageGradientEnd: '#A78BFA',
    tags: ['evening', 'reflection', 'daily'],
    days: [],
  );

  static final _gratitudePlan = GuidedPlan(
    id: 'gratitude-prayer',
    title: 'Grateful Heart',
    subtitle: '7 Days of Thanksgiving',
    description: 'Transform your perspective through gratitude. Each day focuses on a different area of thankfulness.',
    type: GuidedContentType.guidedPrayer,
    totalDays: 7,
    completedDays: 0,
    imageGradientStart: '#F472B6',
    imageGradientEnd: '#FB7185',
    tags: ['gratitude', 'thanksgiving', 'joy'],
    days: [],
  );

  // ============================================================================
  // WORSHIP PLANS
  // ============================================================================

  static final _worshipPlan = GuidedPlan(
    id: 'worship-playlist',
    title: 'Into His Presence',
    subtitle: 'Worship Experience',
    description: 'Curated worship songs to draw you into God\'s presence. Listen, sing along, and let your heart be lifted.',
    type: GuidedContentType.worshipSession,
    totalDays: 1,
    completedDays: 0,
    imageGradientStart: '#F59E0B',
    imageGradientEnd: '#FBBF24',
    tags: ['worship', 'music', 'praise'],
    days: [
      PlanDay(
        dayNumber: 1,
        title: 'Worship Experience',
        content: WorshipContent(
          description: '''Prepare your heart for worship. Find a quiet place where you can sing, listen, and encounter God.

These songs have been selected to lead you on a journey - from praise to intimacy to surrender.''',
          links: [
            WorshipLink(
              title: 'Goodness of God',
              artist: 'Bethel Music',
              url: 'https://www.youtube.com/watch?v=0B_lnQIITxU',
              type: WorshipLinkType.youtube,
            ),
            WorshipLink(
              title: 'Way Maker',
              artist: 'Leeland',
              url: 'https://www.youtube.com/watch?v=iJCV_2H9xD0',
              type: WorshipLinkType.youtube,
            ),
            WorshipLink(
              title: 'Holy Forever',
              artist: 'Chris Tomlin',
              url: 'https://www.youtube.com/watch?v=2BPuWz9VrVw',
              type: WorshipLinkType.youtube,
            ),
            WorshipLink(
              title: 'Build My Life',
              artist: 'Housefires',
              url: 'https://www.youtube.com/watch?v=Z3ByKuiCvNA',
              type: WorshipLinkType.youtube,
            ),
            WorshipLink(
              title: 'Worship Playlist',
              artist: 'Spotify',
              url: 'https://open.spotify.com/playlist/37i9dQZF1DXa4YNZ6zEfPc',
              type: WorshipLinkType.spotify,
            ),
          ],
          reflectionPrompt: 'After worshiping, take a moment to journal what God spoke to your heart.',
        ),
      ),
    ],
  );

  static final _praisePlan = GuidedPlan(
    id: 'praise-anthems',
    title: 'Songs of Praise',
    subtitle: 'Uplifting Worship',
    description: 'High-energy praise songs to lift your spirits and declare God\'s greatness.',
    type: GuidedContentType.worshipSession,
    totalDays: 1,
    completedDays: 0,
    imageGradientStart: '#FB923C',
    imageGradientEnd: '#FDBA74',
    tags: ['praise', 'joy', 'celebration'],
    days: [],
  );

  // ============================================================================
  // BREATHING PLANS
  // ============================================================================

  static final _calmBreathingPlan = GuidedPlan(
    id: 'peace-breathing',
    title: 'Peace & Calm',
    subtitle: 'Breathing Exercise',
    description: 'A simple breathing exercise to calm anxiety and center your mind on God\'s peace. Perfect for stressful moments.',
    type: GuidedContentType.breathingExercise,
    totalDays: 1,
    completedDays: 0,
    imageGradientStart: '#14B8A6',
    imageGradientEnd: '#2DD4BF',
    tags: ['calm', 'peace', 'anxiety'],
    days: [
      PlanDay(
        dayNumber: 1,
        title: 'Peace & Calm',
        content: BreathingContent(
          introduction: '''Find a comfortable position. You can sit or lie down.

This exercise uses a simple 4-7-8 pattern to activate your body's relaxation response and calm your mind.

As you breathe, focus on this truth from Jesus.''',
          inhaleSeconds: 4,
          holdSeconds: 7,
          exhaleSeconds: 8,
          cycles: 4,
          scripture: 'Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid. - John 14:27',
          closingReflection: '''Take a moment to notice how you feel.

God's peace is not the absence of problems - it's His presence in the midst of them.

Carry this peace with you into whatever comes next.''',
        ),
      ),
    ],
  );

  static final _breathPrayerPlan = GuidedPlan(
    id: 'breath-prayer',
    title: 'Breath Prayer',
    subtitle: 'Ancient Practice',
    description: 'Learn the ancient practice of breath prayer - praying with each breath throughout your day.',
    type: GuidedContentType.breathingExercise,
    totalDays: 1,
    completedDays: 0,
    imageGradientStart: '#0D9488',
    imageGradientEnd: '#14B8A6',
    tags: ['prayer', 'ancient', 'centering'],
    days: [
      PlanDay(
        dayNumber: 1,
        title: 'Breath Prayer',
        content: BreathingContent(
          introduction: '''Breath prayer is an ancient Christian practice where we pray short phrases with our breathing.

As you INHALE, pray: "Lord Jesus Christ"
As you EXHALE, pray: "Have mercy on me"

This is called the Jesus Prayer and has been prayed by Christians for over 1,500 years.''',
          inhaleSeconds: 4,
          holdSeconds: 2,
          exhaleSeconds: 6,
          cycles: 6,
          scripture: 'Pray without ceasing. - 1 Thessalonians 5:17',
          closingReflection: '''You can pray this breath prayer anytime, anywhere:
- While waiting in line
- During a stressful meeting
- Before falling asleep
- When you need to center yourself

Each breath becomes a prayer.''',
        ),
      ),
    ],
  );
}

// ============================================================================
// Legacy support for old components during migration
// ============================================================================

class MockGuidedContent {
  static List<GuidedSession> getAll() {
    return [
      ...getScriptureMeditations(),
      ...getGuidedPrayers(),
      ...getWorshipSessions(),
      ...getBreathingExercises(),
    ];
  }

  static List<GuidedSession> getByType(GuidedSessionType type) {
    return getAll().where((s) => s.type == type).toList();
  }

  static List<GuidedSession> getFeatured() {
    return getAll().take(4).toList();
  }

  static List<GuidedSession> getFreeSessions() {
    return getAll().where((s) => !s.isPremium).toList();
  }

  static List<GuidedSession> getScriptureMeditations() => [
    const GuidedSession(
      id: 'psalm-23',
      title: 'Psalm 23: The Lord is My Shepherd',
      description: 'Meditate on the beloved psalm of David',
      type: GuidedSessionType.scriptureMeditation,
      durationMinutes: 10,
      tags: ['peace', 'trust', 'psalms'],
    ),
  ];

  static List<GuidedSession> getGuidedPrayers() => [
    const GuidedSession(
      id: 'morning-prayer',
      title: 'Morning Offering',
      description: 'Start your day with dedication to God',
      type: GuidedSessionType.guidedPrayer,
      durationMinutes: 5,
      tags: ['morning', 'daily'],
    ),
  ];

  static List<GuidedSession> getWorshipSessions() => [
    const GuidedSession(
      id: 'praise',
      title: 'Praise & Adoration',
      description: 'Enter into worship with praise songs',
      type: GuidedSessionType.worshipSession,
      durationMinutes: 10,
      tags: ['worship', 'praise'],
    ),
  ];

  static List<GuidedSession> getBreathingExercises() => [
    const GuidedSession(
      id: 'breath-prayer',
      title: 'Breath Prayer',
      description: 'Ancient practice of praying with breath',
      type: GuidedSessionType.breathingExercise,
      durationMinutes: 5,
      tags: ['breathing', 'centering'],
    ),
  ];
}
