#ifndef FILECACHE_H
#define FILECACHE_H

#include <unordered_map>
#include <string>

class FileCache
{
    std::unordered_map<std::string, FILE*> m_cache;

public:
    void Clear()
    {
        for(auto p = m_cache.begin(); p != m_cache.end(); p++)
            fclose(p->second);
        m_cache.clear();
    }

    std::unordered_map<std::string, FILE*>& Get()
    {
        return m_cache;
    }

    ~FileCache()
    {
        Clear();
    }
};

#endif
