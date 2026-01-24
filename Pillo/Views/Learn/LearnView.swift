import SwiftUI

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingLG) {
                        // Header
                        Text("LEARN")
                            .font(Theme.headerFont)
                            .tracking(2)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.spacingLG)
                            .padding(.top, Theme.spacingMD)

                        // Featured Article
                        FeaturedArticleCard(article: Article.featured)
                            .padding(.horizontal, Theme.spacingLG)

                        // Article List
                        VStack(spacing: 0) {
                            ForEach(Article.articles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    ArticleRow(article: article)
                                }

                                if article.id != Article.articles.last?.id {
                                    Divider()
                                        .background(Theme.border)
                                        .padding(.horizontal, Theme.spacingLG)
                                }
                            }
                        }
                        .padding(.bottom, Theme.spacingXXL)
                    }
                }
            }
        }
    }
}

struct FeaturedArticleCard: View {
    let article: Article

    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article)) {
            VStack(alignment: .leading, spacing: Theme.spacingMD) {
                Text(article.title.uppercased())
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)

                Text("\(article.readTime) min read")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }
}

struct ArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text(article.title)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            HStack {
                Text(article.subtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Text("\(article.readTime) min")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.vertical, Theme.spacingMD)
        .padding(.horizontal, Theme.spacingLG)
    }
}

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingLG) {
                    // Title
                    Text(article.title)
                        .font(Theme.displayFont)
                        .foregroundColor(Theme.textPrimary)

                    // Subtitle
                    Text(article.subtitle)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)

                    Text("\(article.readTime) min read")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)

                    Divider()
                        .background(Theme.border)

                    // Content
                    Text(article.content)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                        .lineSpacing(8)
                }
                .padding(Theme.spacingLG)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Article Model

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let readTime: Int
    let content: String

    static let featured = Article(
        title: "Why Your Multivitamin Might Be Canceling Itself Out",
        subtitle: "The hidden conflicts inside your daily vitamin",
        readTime: 3,
        content: """
        That comprehensive multivitamin you take every morning? It might be working against itself.

        Here's the uncomfortable truth: many multivitamins contain minerals that compete for absorption when taken together. Calcium and iron are the biggest offenders—they use the same transport pathways in your gut, meaning they literally fight each other for entry into your bloodstream.

        THE CALCIUM-IRON PROBLEM

        When calcium and iron are taken together, calcium can reduce iron absorption by up to 50%. This is significant if you're taking a multivitamin that contains both (most do) and you're trying to address iron deficiency.

        The solution? If you need both, take them at different times of day. Iron absorbs best on an empty stomach in the morning, while calcium can be taken with meals later in the day.

        ZINC VS. COPPER

        Another common conflict: zinc and copper. High-dose zinc supplements (above 40mg) can deplete your copper levels over time. Many people taking zinc for immune support don't realize they should also supplement copper—or at least space out their intake.

        WHAT YOU CAN DO

        1. Consider splitting your supplement intake across the day
        2. Take iron separately from calcium-containing supplements
        3. If taking high-dose zinc, add copper to your routine
        4. Take fat-soluble vitamins (A, D, E, K) with meals containing fat

        The good news? Once you understand these interactions, you can easily optimize your routine. It's not about taking more—it's about taking smarter.
        """
    )

    static let articles: [Article] = [
        Article(
            title: "The Iron-Calcium War",
            subtitle: "Why these minerals hate each other",
            readTime: 2,
            content: """
            Calcium and iron have a complicated relationship. When taken together, they compete for the same absorption pathways in your intestines—and calcium usually wins.

            Studies show that calcium can inhibit iron absorption by up to 50% when taken at the same meal. This is particularly important for:

            • Women with heavy periods who need extra iron
            • Vegetarians and vegans who rely on plant-based iron
            • Anyone with diagnosed iron deficiency

            THE SCIENCE

            Both minerals are absorbed in the duodenum (the first part of your small intestine) through a process that involves similar transport proteins. When both are present, they compete for these limited transporters.

            Calcium has a higher affinity for these proteins, meaning iron gets left behind.

            THE SOLUTION

            Space your calcium and iron supplements at least 2 hours apart—ideally more. Take iron in the morning on an empty stomach (it absorbs better this way anyway), and save calcium for afternoon or evening.

            Vitamin C can help boost iron absorption, so consider pairing your iron supplement with a vitamin C source.
            """
        ),
        Article(
            title: "Fat-Soluble 101",
            subtitle: "A, D, E, K: What they need to work",
            readTime: 3,
            content: """
            Vitamins A, D, E, and K share something important: they're fat-soluble. This means they require dietary fat to be absorbed properly.

            Take these vitamins on an empty stomach, and you might as well be throwing money away.

            HOW FAT-SOLUBLE VITAMINS WORK

            Unlike water-soluble vitamins (like vitamin C and the B vitamins), fat-soluble vitamins don't dissolve in water. They dissolve in fat.

            When you eat a meal containing fat, your body releases bile salts that emulsify the fat into tiny droplets. These droplets form structures called micelles, which can carry fat-soluble vitamins through your intestinal wall and into your bloodstream.

            No fat? No micelles. No absorption.

            PRACTICAL APPLICATION

            Always take fat-soluble vitamins with a meal containing some fat. This doesn't mean you need a high-fat meal—a tablespoon of olive oil, some avocado, or even a few nuts is enough.

            Breakfast is ideal for vitamin D specifically, as some people find it can affect sleep if taken too late in the day.

            THE VITAMIN D + K2 CONNECTION

            These two work as a team. Vitamin D helps your body absorb calcium, while vitamin K2 directs that calcium to your bones (instead of your arteries). Taking D without K2 isn't dangerous, but you're not getting the full benefit.
            """
        ),
        Article(
            title: "Empty Stomach: What It Actually Means",
            subtitle: "Timing tips that actually matter",
            readTime: 2,
            content: """
            "Take on an empty stomach" is one of the most common supplement instructions—and one of the most misunderstood.

            WHAT "EMPTY STOMACH" ACTUALLY MEANS

            An empty stomach isn't just "before you eat." It means:
            • At least 2 hours after your last meal
            • At least 30-60 minutes before your next meal

            Your stomach isn't truly empty until food has moved into your small intestine, which takes about 2 hours for most meals.

            WHY IT MATTERS

            Some supplements absorb better without food interference:

            IRON: Food can reduce iron absorption by up to 50%. Vitamin C helps, but other meal components (calcium, tannins in tea/coffee, phytates in grains) can seriously impair absorption.

            AMINO ACIDS: L-tyrosine, L-theanine, and other single amino acids compete with dietary protein for absorption. Taking them with a protein-rich meal defeats the purpose.

            CERTAIN PROBIOTICS: Some strains survive better when not exposed to stomach acid produced during digestion.

            THE PRACTICAL APPROACH

            For most people, "empty stomach" means:
            • First thing in the morning, 30-60 min before breakfast
            • Or 2+ hours after dinner, before bed

            Set your supplements on your nightstand or by your coffee maker as a reminder.
            """
        ),
        Article(
            title: "The $50/Month Mistake",
            subtitle: "How bad timing wastes your supplement budget",
            readTime: 4,
            content: """
            The average American taking supplements spends about $50-100 per month on their regimen. What if half of that was going down the drain—literally?

            Poor timing and incorrect pairing can reduce supplement absorption dramatically. Here's what you might be losing:

            VITAMIN D TAKEN ON AN EMPTY STOMACH

            Vitamin D is fat-soluble. Studies show absorption can be 32% higher when taken with a fat-containing meal versus without food. That's roughly one-third of your vitamin D potentially wasted.

            CALCIUM WITH YOUR MULTIVITAMIN

            Most multivitamins contain iron. Taking calcium at the same time can reduce iron absorption by up to 50%. If you're paying for iron in your multi, you're getting half of what you paid for.

            FISH OIL ON AN EMPTY STOMACH

            Those expensive omega-3 capsules? They're fat (obviously), and they absorb better with other fats. Taking fish oil with a meal can increase absorption by up to 3x compared to fasting.

            THE HIDDEN COSTS

            Let's do the math on a typical supplement routine:

            • Vitamin D 5000 IU: ~$15/month
              - Taken wrong: Losing ~$5/month

            • Fish Oil: ~$25/month
              - Taken wrong: Losing ~$8-12/month

            • Iron + Calcium same time: ~$10/month each
              - Losing half the iron: ~$5/month

            That's potentially $20-25/month wasted—$240-300 per year—just from bad timing.

            THE FIX IS FREE

            The good news? Optimizing your routine costs nothing. It just requires:
            1. Understanding which supplements need food
            2. Knowing which supplements compete
            3. Spacing things appropriately throughout the day

            That's exactly why this app exists.
            """
        )
    ]
}

#Preview {
    LearnView()
        .preferredColorScheme(.dark)
}
