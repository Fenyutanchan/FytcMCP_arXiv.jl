# Sample RSS XML for testing (mimics real arXiv RSS structure)
const SAMPLE_RSS = raw"""<?xml version='1.0' encoding='UTF-8'?>
<rss xmlns:arxiv="http://arxiv.org/schemas/atom" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
  <channel>
    <title>hep-ph updates on arXiv.org</title>
    <link>http://rss.arxiv.org/rss/hep-ph</link>
    <description>hep-ph updates on the arXiv.org e-print archive.</description>
    <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
    <item>
      <title>Test Paper One: A Study of Something</title>
      <link>https://arxiv.org/abs/2605.10001</link>
      <description>arXiv:2605.10001v1 Announce Type: new
Abstract: This is the abstract of the first test paper. It contains some interesting results about physics.</description>
      <guid isPermaLink="false">oai:arXiv.org:2605.10001v1</guid>
      <category>hep-ph</category>
      <category>hep-th</category>
      <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
      <arxiv:announce_type>new</arxiv:announce_type>
      <dc:rights>http://arxiv.org/licenses/nonexclusive-distrib/1.0/</dc:rights>
      <dc:creator>Alice Smith, Bob Jones</dc:creator>
    </item>
    <item>
      <title>Cross-Listed Paper: Insights from Another Field</title>
      <link>https://arxiv.org/abs/2605.10002</link>
      <description>arXiv:2605.10002v1 Announce Type: cross
Abstract: This is the abstract of the cross-listed paper. It bridges hep-ph and astro-ph.</description>
      <guid isPermaLink="false">oai:arXiv.org:2605.10002v1</guid>
      <category>hep-ph</category>
      <category>astro-ph.HE</category>
      <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
      <arxiv:announce_type>cross</arxiv:announce_type>
      <dc:rights>http://arxiv.org/licenses/nonexclusive-distrib/1.0/</dc:rights>
      <dc:creator>Carol Lee</dc:creator>
    </item>
    <item>
      <title>Test Paper Three: Another New Submission</title>
      <link>https://arxiv.org/abs/2605.10003</link>
      <description>arXiv:2605.10003v1 Announce Type: new
Abstract: This is the abstract of the third test paper. It is longer than the others to test truncation functionality. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.</description>
      <guid isPermaLink="false">oai:arXiv.org:2605.10003v1</guid>
      <category>hep-ph</category>
      <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
      <arxiv:announce_type>new</arxiv:announce_type>
      <dc:rights>http://arxiv.org/licenses/nonexclusive-distrib/1.0/</dc:rights>
      <dc:creator>David Chen, Eve Wang, Frank Liu</dc:creator>
    </item>
    <item>
      <title>Replaced Paper: Updated Results</title>
      <link>https://arxiv.org/abs/2605.10004</link>
      <description>arXiv:2605.10004v2 Announce Type: rep
Abstract: This is a replaced paper with updated results.</description>
      <guid isPermaLink="false">oai:arXiv.org:2605.10004v2</guid>
      <category>hep-ph</category>
      <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
      <arxiv:announce_type>rep</arxiv:announce_type>
      <dc:rights>http://arxiv.org/licenses/nonexclusive-distrib/1.0/</dc:rights>
      <dc:creator>Grace Kim</dc:creator>
    </item>
  </channel>
</rss>"""

# Minimal RSS with no items
const EMPTY_RSS = raw"""<?xml version='1.0' encoding='UTF-8'?>
<rss version="2.0">
  <channel>
    <title>empty updates on arXiv.org</title>
    <link>http://rss.arxiv.org/rss/empty</link>
    <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
  </channel>
</rss>"""

# RSS with malformed/missing fields
const MINIMAL_ITEM_RSS = raw"""<?xml version='1.0' encoding='UTF-8'?>
<rss xmlns:arxiv="http://arxiv.org/schemas/atom" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
  <channel>
    <title>minimal updates on arXiv.org</title>
    <pubDate>Wed, 21 May 2026 00:00:00 -0400</pubDate>
    <item>
      <title>Minimal Paper</title>
      <link>https://arxiv.org/abs/2605.99999</link>
      <description>arXiv:2605.99999v1 Announce Type: new
Abstract: Short abstract.</description>
    </item>
  </channel>
</rss>"""
