import re
import yaml
from bs4 import BeautifulSoup as bs
import spacy
nlp = spacy.load('en_core_web_sm')


def extract_skillset(description_html):
    soup = bs(description_html, 'html.parser')
    skill_html_lists = extract_skill_html_lists(soup)
    if not skill_html_lists:
        text = ' '.join([element.text for element in soup])
        return regex_extraction(text)
    skillset = set()
    for html_list in skill_html_lists:
        for list_item in html_list.select('li'):
            skillset.update(extract_skills_from_list_item(list_item.text))
    return list(skillset)


def extract_job_level(description_html):
    if 'senior' in description_html:
        return 'senior'
    elif 'Senior' in description_html:
        return 'senior'
    else:
        return 'junior'


KEYWORD = ['Python', 'C', 'C\+\+', 'C#', '.Net', 'Go', 'PHP', 'HTML', 'CSS', 'Java', 'Scala', 'Ruby',
           'JavaScript', 'JS', 'TypeScript', 'TS', 'Node.js', 'NodeJs', 'Vue', 'React',
           'gRPC', 'Docker', 'Kubernetes',
           'SQL', 'MySQL',
           'CI\/CD',
           'Rest API', 'Restful API',
           'Google Cloud', 'Azure', 'AWS']
REGEX = re.compile(
    rf'(?:[\s,.!?:;])({"|".join(KEYWORD)})(?:[\s,.!?:;])', flags=re.I)


def regex_extraction(description):
    skills = re.findall(REGEX, description)
    return list(set(skills))


def extract_skill_html_lists(description_soup):
    skill_keywords = ['requirement', 'tech', 'skill', 'experience']
    list_tags = set(['ul', 'ol'])
    html_lists = []
    for p in description_soup.select('p'):
        text = p.text.lower()
        if any(kw in text for kw in skill_keywords):
            cur_element = p.next_sibling
            for _ in range(2):
                if cur_element is None:
                    continue
                if cur_element.text.strip() == '':
                    cur_element = cur_element.next_sibling
                elif cur_element.name in list_tags:
                    html_lists.append(cur_element)
    return html_lists


def extract_skills_from_list_item(item_text):
    doc = nlp(item_text)
    if len(doc) <= 3:
        return simple_extraction(doc)
    else:
        return complex_extraction(doc)


def simple_extraction(doc):
    return set(tok.text for tok in doc
               if tok.pos_ != 'SYM')


def complex_extraction(doc):
    skills = set()
    for token in doc:
        if token.pos_ == 'PROPN':
            skill = expand_token_to_skill(token)
            skills.add(skill)
    return skills


def lemmatize_noun(text):
    return ' '.join([tok.lemma_ if tok.pos_ == 'NOUN' else tok.text
                     for tok in nlp(text)])


def expand_token_to_skill(token):
    collocation = find_collocation(token)
    if collocation is None:
        return token.text
    sorted_tokens = sorted([token, collocation], key=lambda t: t.idx)
    skill = ' '.join([tok.text for tok in sorted_tokens])
    return skill


def find_collocation(token):
    if token.dep_ == 'compound':
        return token.head
    return None


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 2:
        print(f'[ ERROR ] please specify the file with job description in command line')
        exit(1)

    with open(sys.argv[1], 'r') as f:
        description = f.read().strip()
    skillset = extract_skillset(description)
    skillset = list(set(map(str.lower, skillset)))
    job_level = extract_job_level(description)
    
    extracted = {
        "skillset": skillset,
        "job_level": job_level,
    }
    
    extracted = yaml.dump(extracted)
    print(extracted)
