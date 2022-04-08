/*
 * Copyright (C) 2021 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#ifndef KRAKENBRIDGE_DOCUMENT_H
#define KRAKENBRIDGE_DOCUMENT_H

#include "container_node.h"

namespace kraken {

// A document (https://dom.spec.whatwg.org/#concept-document) is the root node
// of a tree of DOM nodes, generally resulting from the parsing of a markup
// (typically, HTML) resource.
class Document : public Node {
  DEFINE_WRAPPERTYPEINFO();

 public:
  using ImplType = Document*;

 private:
};

// void bindDocument(ExecutionContext* context);
//
// using TraverseHandler = std::function<bool(Node*)>;
//
// void traverseNode(Node* node, TraverseHandler handler);
//
// class DocumentCookie {
// public:
//  DocumentCookie() = default;
//
//  std::string getCookie();
//  void setCookie(std::string& str);
//
// private:
//  std::unordered_map<std::string, std::string> cookiePairs;
//};

// class Document : public Node {
// public:
//  static JSClassID classId;
//  static Document* create(JSContext* ctx);
//  static JSValue constructor(ExecutionContext* context);
//  static JSValue prototype(ExecutionContext* context);
//  explicit Document();
//
//  DEFINE_FUNCTION(createEvent);
//  DEFINE_FUNCTION(createElement);
//  DEFINE_FUNCTION(createTextNode);
//  DEFINE_FUNCTION(createDocumentFragment);
//  DEFINE_FUNCTION(createComment);
//  DEFINE_FUNCTION(getElementById);
//  DEFINE_FUNCTION(getElementsByTagName);
//  DEFINE_FUNCTION(getElementsByClassName);
//
//  DEFINE_PROTOTYPE_READONLY_PROPERTY(nodeName);
//  DEFINE_PROTOTYPE_READONLY_PROPERTY(all);
//  DEFINE_PROTOTYPE_READONLY_PROPERTY(documentElement);
//  DEFINE_PROTOTYPE_READONLY_PROPERTY(children);
//  DEFINE_PROTOTYPE_READONLY_PROPERTY(head);
//
//  DEFINE_PROTOTYPE_PROPERTY(cookie);
//  DEFINE_PROTOTYPE_PROPERTY(body);
//
//  JSValue getElementConstructor(ExecutionContext* context, const std::string& tagName);
//  bool isCustomElement(const std::string& tagName);
//
//  int32_t requestAnimationFrame(FrameCallback* frameCallback);
//  void cancelAnimationFrame(uint32_t callbackId);
//  void trace(JSRuntime* rt, JSValue val, JS_MarkFunc* mark_func) const override;
//  void dispose() const override;
//
// private:
//  void removeElementById(JSAtom id, Element* element);
//  void addElementById(JSAtom id, Element* element);
//  Element* getDocumentElement();
//  std::unordered_map<JSAtom, std::vector<Element*>> m_elementMapById;
//  Element* m_documentElement{nullptr};
//  std::unique_ptr<DocumentCookie> m_cookie;
//
//  ScriptAnimationController* m_scriptAnimationController;
//
//  void defineElement(const std::string& tagName, Element* constructor);
//
//  bool event_registered{false};
//  bool document_registered{false};
//  std::unordered_map<std::string, Element*> elementConstructorMap;
//};

}  // namespace kraken

#endif  // KRAKENBRIDGE_DOCUMENT_H
