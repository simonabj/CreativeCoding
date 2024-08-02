import xml.sax
import io

class XMLHandler(xml.sax.ContentHandler):
    def __init__(self):
        self.current_tag = ""
        self.current_parent = ""
        self.data = {
            "thinking": "",
            "speak": "",
            "memory": [],
            "recall": []
        }
        self.current_entry = ""

    def reset(self):
        self.current_tag = ""
        self.current_parent = ""
        self.current_entry = ""
        self.data = {
            "thinking": "",
            "speak": "",
            "memory": [],
            "recall": []
        }

    def startElement(self, tag, attributes):
        self.current_tag = tag
        if tag in ["memory", "recall"]:
            self.current_parent = tag
        elif tag == "entry":
            self.current_entry = ""

    def endElement(self, tag):
        if tag in ["memory", "recall"]:
            self.current_parent = ""
        elif tag == "entry":
            if self.current_parent == "memory":
                self.data["memory"].append(self.current_entry.strip())
            elif self.current_parent == "recall":
                self.data["recall"].append(self.current_entry.strip())
            self.current_entry = ""
        self.current_tag = ""

    def characters(self, content):
        if self.current_tag == "thinking":
            self.data["thinking"] += content
        elif self.current_tag == "speak":
            self.data["speak"] += content
        elif self.current_tag == "entry":
            self.current_entry += content

class ResponseParser:
    def __init__(self):
        self.handler = XMLHandler()

    def parse(self, text):
        self.handler.reset()
        text = text.replace("\n", "")
        xml.sax.parseString(f"<root>{text}</root>", self.handler)
        return self.handler.data