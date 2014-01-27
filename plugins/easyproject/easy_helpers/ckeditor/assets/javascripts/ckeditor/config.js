/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
    // Define changes to default configuration here. For example:
    // config.language = 'fr';
    // config.uiColor = '#AADC6E';

    config.removePlugins = 'scayt';
    config.entities_latin = false;
    config.disableNativeSpellChecker = true;
    config.skin = 'moono';
    config.resize_enabled = true;
    config.toolbarStartupExpanded = true;
    config.toolbarCanCollapse = false;
    config.extraAllowedContent = 'table pre code big small img; *[id](*); *[class](*); *[style](*)';
    config.tabSpaces = 4;
    config.contentsCss = '/plugin_assets/easy_extensions/stylesheets/basic.css';
    config.toolbar_Full = [
    ['Bold','Italic','Underline','Strike','NumberedList','BulletedList','Subscript','Superscript','-','Outdent','Indent','Blockquote'],
    ['Styles','Format','Font','FontSize'],
    ['TextColor','BGColor'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Link','Unlink','Anchor'],
    ['Image','Table','HorizontalRule','Smiley','SpecialChar','-','Maximize', 'ShowBlocks'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord','-','Print', 'SpellChecker'],
    ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
    ['Source','Preview','Templates']
    ];

    config.toolbar_Extended = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['Image','PasteFromWord','Table','Source'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Format','Font','FontSize'],
    ['Table','HorizontalRule'],
    ['Cut','Copy','Paste','PasteText']
    ];

    config.toolbar_Basic = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['Image','PasteFromWord','Table','Source']
    ];

    config.toolbar_Publishing = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['Image','PasteFromWord','Table','Source']
    ];

    config.toolbar_Noticeboard = [
    ['Bold','Italic','Underline','Strike'],['Format','FontSize'],
    ['TextColor','BGColor'],['Link','Unlink'], ['NumberedList','BulletedList'],
    ['Image','PasteFromWord','Table','Source']
    ];
};
