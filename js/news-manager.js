// 新闻数据管理器
class NewsManager {
    constructor() {
        this.platforms = {
            twitter: 'X (Twitter)',
            tiktok: 'TikTok',
            weibo: '微博',
            reddit: 'Reddit'
        };
        this.updateInterval = 30 * 60 * 1000; // 30分钟
        this.maxRetries = 3;
    }

    // 获取X(Twitter)热点数据
    async getTwitterNews() {
        try {
            // 模拟API调用 - 实际部署时需要真实API
            return await this.mockTwitterData();
        } catch (error) {
            console.error('获取Twitter数据失败:', error);
            return [];
        }
    }

    // 获取TikTok热点数据
    async getTikTokNews() {
        try {
            return await this.mockTikTokData();
        } catch (error) {
            console.error('获取TikTok数据失败:', error);
            return [];
        }
    }

    // 获取微博热点数据
    async getWeiboNews() {
        try {
            return await this.mockWeiboData();
        } catch (error) {
            console.error('获取微博数据失败:', error);
            return [];
        }
    }

    // 获取Reddit热点数据
    async getRedditNews() {
        try {
            return await this.mockRedditData();
        } catch (error) {
            console.error('获取Reddit数据失败:', error);
            return [];
        }
    }

    // 模拟Twitter数据
    async mockTwitterData() {
        const topics = [
            'Breaking: Major tech announcement today',
            'Climate summit reaches historic agreement',
            'New AI breakthrough announced',
            'Global markets react to policy changes',
            'Sports championship finals tonight'
        ];
        
        const topicsZh = [
            '突发：重大科技公告今日发布',
            '气候峰会达成历史性协议',
            '新AI突破宣布',
            '全球市场对政策变化作出反应',
            '体育锦标赛决赛今晚举行'
        ];

        return topics.map((title, index) => ({
            title: title,
            titleZh: topicsZh[index],
            engagement: this.generateEngagement('twitter'),
            time: this.generateTime(),
            url: `https://twitter.com/trending/${index + 1}`,
            platform: 'twitter'
        }));
    }

    // 模拟TikTok数据
    async mockTikTokData() {
        const trends = [
            'Viral dance challenge sweeps the nation',
            'New food trend everyone\'s trying',
            'Comedy sketch breaks internet',
            'DIY life hack goes viral',
            'Pet video melts hearts globally',
            'Fashion trend takes over social media',
            'Travel destination becomes overnight sensation',
            'Fitness challenge inspires millions',
            'Cooking tutorial breaks records',
            'Tech review goes viral'
        ];
        
        const trendsZh = [
            '病毒式舞蹈挑战席卷全国',
            '人人都在尝试的新美食趋势',
            '喜剧小品打破网络',
            'DIY生活技巧走红',
            '宠物视频温暖全球人心',
            '时尚趋势占领社交媒体',
            '旅游目的地一夜爆红',
            '健身挑战激励数百万人',
            '烹饪教程打破记录',
            '科技评测走红'
        ];

        return trends.slice(0, 10).map((title, index) => ({
            title: title,
            titleZh: trendsZh[index],
            engagement: this.generateEngagement('tiktok'),
            time: this.generateTime(),
            url: `https://tiktok.com/trending/${index + 1}`,
            platform: 'tiktok'
        }));
    }

    // 模拟微博数据
    async mockWeiboData() {
        const hotTopics = [
            '娱乐圈重磅消息引发关注',
            '社会热点事件持续发酵',
            '体育赛事精彩瞬间回顾',
            '科技新品发布备受期待',
            '美食探店视频走红网络'
        ];

        return hotTopics.map((title, index) => ({
            title: title,
            titleZh: title,
            engagement: this.generateEngagement('weibo'),
            time: this.generateTime(),
            url: `https://weibo.com/hot/${index + 1}`,
            platform: 'weibo'
        }));
    }

    // 模拟Reddit数据
    async mockRedditData() {
        const posts = [
            'AskReddit: What\'s your best life hack?',
            'Gaming community discovers new strategy',
            'Science explanation goes viral',
            'Programming tip saves developers hours',
            'Movie theory blows minds'
        ];
        
        const postsZh = [
            '提问：你最好的生活技巧是什么？',
            '游戏社区发现新策略',
            '科学解释走红',
            '编程技巧为开发者节省数小时',
            '电影理论让人大开眼界'
        ];

        return posts.map((title, index) => ({
            title: title,
            titleZh: postsZh[index],
            engagement: this.generateEngagement('reddit'),
            time: this.generateTime(),
            url: `https://reddit.com/r/AskReddit/${index + 1}`,
            platform: 'reddit'
        }));
    }

    // 生成互动数据
    generateEngagement(platform) {
        const ranges = {
            twitter: [50, 300],
            tiktok: [500, 5000],
            weibo: [100, 600],
            reddit: [5, 30]
        };
        
        const [min, max] = ranges[platform];
        const value = Math.floor(Math.random() * (max - min + 1)) + min;
        
        if (platform === 'tiktok') {
            return value >= 1000 ? `${(value/1000).toFixed(1)}M` : `${value}K`;
        } else if (platform === 'reddit') {
            return `${value}K`;
        } else {
            return `${value}K`;
        }
    }

    // 生成时间戳
    generateTime() {
        const times = ['30分钟前', '1小时前', '2小时前', '3小时前', '4小时前', '5小时前', '6小时前'];
        return times[Math.floor(Math.random() * times.length)];
    }

    // 获取所有平台新闻
    async getAllNews() {
        const newsData = {};
        
        try {
            newsData.twitter = await this.getTwitterNews();
            newsData.tiktok = await this.getTiktokNews();
            newsData.weibo = await this.getWeiboNews();
            newsData.reddit = await this.getRedditNews();
            
            // 保存到本地存储
            this.saveToLocalStorage(newsData);
            
        } catch (error) {
            console.error('获取新闻数据失败:', error);
            // 从本地存储获取缓存数据
            return this.getFromLocalStorage();
        }
        
        return newsData;
    }

    // 保存到本地存储
    saveToLocalStorage(data) {
        const cacheData = {
            data: data,
            timestamp: new Date().toISOString(),
            version: '1.0'
        };
        localStorage.setItem('newsCache', JSON.stringify(cacheData));
    }

    // 从本地存储获取
    getFromLocalStorage() {
        const cached = localStorage.getItem('newsCache');
        if (cached) {
            const cacheData = JSON.parse(cached);
            const cacheTime = new Date(cacheData.timestamp);
            const now = new Date();
            const hoursDiff = (now - cacheTime) / (1000 * 60 * 60);
            
            // 如果缓存不超过24小时，返回缓存数据
            if (hoursDiff < 24) {
                console.log('使用缓存数据');
                return cacheData.data;
            }
        }
        return null;
    }

    // 检查是否需要更新
    shouldUpdate() {
        const cached = localStorage.getItem('newsCache');
        if (!cached) return true;
        
        const cacheData = JSON.parse(cached);
        const cacheTime = new Date(cacheData.timestamp);
        const now = new Date();
        const minutesDiff = (now - cacheTime) / (1000 * 60);
        
        return minutesDiff >= 30; // 30分钟后更新
    }
}

// UI管理器
class UIManager {
    constructor() {
        this.newsManager = new NewsManager();
        this.isLoading = false;
    }

    // 显示加载状态
    showLoading() {
        const loading = document.getElementById('loading');
        const container = document.getElementById('newsContainer');
        
        loading.classList.remove('hidden');
        container.classList.add('hidden');
        this.isLoading = true;
    }

    // 隐藏加载状态
    hideLoading() {
        const loading = document.getElementById('loading');
        const container = document.getElementById('newsContainer');
        
        loading.classList.add('hidden');
        container.classList.remove('hidden');
        this.isLoading = false;
    }

    // 渲染新闻卡片
    renderNewsCard(news) {
        const badges = {
            twitter: 'twitter-badge',
            tiktok: 'tiktok-badge',
            weibo: 'weibo-badge',
            reddit: 'reddit-badge'
        };

        const icons = {
            twitter: 'ri-twitter-x-line',
            tiktok: 'ri-tiktok-line',
            weibo: 'ri-weibo-line',
            reddit: 'ri-reddit-line'
        };

        return `
            <div class="news-card bg-gray-50 rounded-lg p-4 hover:bg-gray-100 cursor-pointer" data-url="${news.url}">
                <div class="flex justify-between items-start mb-2">
                    <div class="flex items-center">
                        <i class="${icons[news.platform]} text-lg mr-2"></i>
                        <span class="platform-badge ${badges[news.platform]}">${news.platform}</span>
                    </div>
                    <span class="text-xs text-gray-500">${news.time}</span>
                </div>
                <h3 class="font-medium text-gray-900 mb-1">${news.title}</h3>
                <h3 class="font-medium text-gray-700 mb-2">${news.titleZh}</h3>
                <div class="flex justify-between items-center">
                    <span class="text-sm text-gray-500">
                        <i class="ri-fire-line text-orange-500 mr-1"></i>
                        ${news.engagement} 互动
                    </span>
                    <i class="ri-external-link-line text-blue-500"></i>
                </div>
            </div>
        `;
    }

    // 渲染平台新闻
    renderPlatformNews(platform, news) {
        const container = document.getElementById(`${platform}News`);
        if (!container) return;

        container.innerHTML = news.map(item => this.renderNewsCard(item)).join('');
    }

    // 更新最后更新时间
    updateLastUpdateTime() {
        const now = new Date();
        const timeString = now.toLocaleString('zh-CN');
        const element = document.getElementById('lastUpdate');
        if (element) {
            element.textContent = `最后更新: ${timeString}`;
        }
    }

    // 加载并显示新闻
    async loadAndDisplayNews() {
        if (this.isLoading) return;

        this.showLoading();

        try {
            // 检查是否需要更新
            const shouldUpdate = this.newsManager.shouldUpdate();
            
            let newsData;
            if (shouldUpdate) {
                console.log('获取最新新闻数据...');
                newsData = await this.newsManager.getAllNews();
            } else {
                console.log('使用缓存数据...');
                newsData = this.newsManager.getFromLocalStorage();
            }

            if (newsData) {
                // 渲染各平台新闻
                this.renderPlatformNews('twitter', newsData.twitter || []);
                this.renderPlatformNews('tiktok', newsData.tiktok || []);
                this.renderPlatformNews('weibo', newsData.weibo || []);
                this.renderPlatformNews('reddit', newsData.reddit || []);

                // 更新时间
                this.updateLastUpdateTime();
            } else {
                // 如果没有数据，显示错误信息
                this.showError('无法获取新闻数据，请稍后重试。');
            }
        } catch (error) {
            console.error('加载新闻失败:', error);
            this.showError('加载新闻时出现错误，请刷新页面重试。');
        } finally {
            this.hideLoading();
        }
    }

    // 显示错误信息
    showError(message) {
        const container = document.getElementById('newsContainer');
        container.innerHTML = `
            <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
                <i class="ri-error-warning-line text-3xl text-red-500 mb-2"></i>
                <p class="text-red-700">${message}</p>
                <button onclick="location.reload()" class="mt-4 bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700">
                    重新加载
                </button>
            </div>
        `;
        container.classList.remove('hidden');
        this.hideLoading();
    }

    // 刷新新闻
    async refreshNews() {
        await this.loadAndDisplayNews();
    }

    // 初始化
    init() {
        // 加载新闻
        this.loadAndDisplayNews();

        // 设置自动刷新
        setInterval(() => {
            this.loadAndDisplayNews();
        }, 30 * 60 * 1000); // 30分钟

        // 添加点击事件
        document.addEventListener('click', (e) => {
            const newsCard = e.target.closest('.news-card');
            if (newsCard) {
                const url = newsCard.dataset.url;
                if (url) {
                    window.open(url, '_blank');
                }
            }
        });
    }
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    const uiManager = new UIManager();
    uiManager.init();

    // 全局刷新函数
    window.refreshNews = () => uiManager.refreshNews();
});

// Service Worker注册（用于离线支持）
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}