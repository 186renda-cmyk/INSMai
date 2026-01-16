import requests
import xml.etree.ElementTree as ET
import json

# 配置信息
HOST = "ins-mai.top"
KEY = "a1b40e73f54b4eef97a6002663f8e89a"
KEY_LOCATION = f"https://{HOST}/{KEY}.txt"
SITEMAP_FILE = "sitemap.xml"
INDEXNOW_ENDPOINT = "https://api.indexnow.org/indexnow"
# 也可以使用 Bing 的端点: https://www.bing.com/indexnow

def get_urls_from_sitemap(sitemap_path):
    """从 sitemap.xml 中提取 URL"""
    urls = []
    try:
        tree = ET.parse(sitemap_path)
        root = tree.getroot()
        # 处理 XML 命名空间
        namespace = {'ns': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
        
        for url in root.findall('ns:url', namespace):
            loc = url.find('ns:loc', namespace)
            if loc is not None and loc.text:
                urls.append(loc.text)
        
        print(f"成功从 {sitemap_path} 提取到 {len(urls)} 个 URL")
        return urls
    except Exception as e:
        print(f"读取 sitemap.xml 失败: {e}")
        return []

def submit_to_indexnow(url_list):
    """提交 URL 列表到 IndexNow"""
    if not url_list:
        print("没有 URL 需要提交")
        return

    payload = {
        "host": HOST,
        "key": KEY,
        "keyLocation": KEY_LOCATION,
        "urlList": url_list
    }

    headers = {
        "Content-Type": "application/json; charset=utf-8"
    }

    try:
        response = requests.post(INDEXNOW_ENDPOINT, data=json.dumps(payload), headers=headers)
        
        if response.status_code == 200:
            print("✅ 提交成功！IndexNow 已接收请求。")
        elif response.status_code == 202:
            print("✅ 提交成功！IndexNow 已接收请求（处理中）。")
        else:
            print(f"❌ 提交失败。状态码: {response.status_code}")
            print(f"响应内容: {response.text}")
            
    except Exception as e:
        print(f"❌ 请求发生错误: {e}")

if __name__ == "__main__":
    print("开始 IndexNow 自动化提交...")
    
    # 1. 获取 URL 列表
    urls = get_urls_from_sitemap(SITEMAP_FILE)
    
    # 2. 提交到 IndexNow
    if urls:
        print(f"准备提交以下 URL (前5个):")
        for u in urls[:5]:
            print(f" - {u}")
        if len(urls) > 5:
            print(f" ... 等共 {len(urls)} 个")
            
        submit_to_indexnow(urls)
