var PageLayout = {
    current_tab: 1,
    tab_element: false,
    tabs_initialized : false,
    __panelID: false,
    getActiveTab: function() {
        var result = PageLayout.tab_element.find("li[aria-selected='true']");
        if( result.length >= 1 )
            return result;
        return false;
    },
    getActivePanelId: function() {
        var activeTab = PageLayout.getActiveTab();
        if( activeTab )
            return PageLayout.getActiveTab().attr("aria-controls");
        else
            return PageLayout.__panelID + '-0';
    },
    initEditableTabs: function(options) {

        var o = $.extend({}, {
            active: 0,
            elementID: 'easy_jquery_tabs',
            panelID: 'easy_jquery_tab' //panelid = panelID-<tab number> expect to panels have class panelID
        }, options);

        PageLayout.__panelID = o.panelID;
        setAttrToUrl = PageLayout.setAttrToUrl;
      
        var easy_jquery_tabs = $('#'+o.elementID).tabs({
            active: o.active,
            beforeLoad: function( event, ui ) {
              ui.jqXHR.error(function() {
                ui.panel.html("Couldn't load this tab. We'll try to fix this as soon as possible.");
              });
            },
            load: function( event, ui ) {
              $(ui.tab).attr("href", '#' + $(ui.panel).find('.'+o.panelID).attr('id'));
              var $edit_link = $(ui.tab).closest("li").find(".icon-edit");
              var href = $edit_link.attr("href");
              href = setAttrToUrl(href, 'is_preloaded', true)
              $edit_link.attr('href', href);
              easy_jquery_tabs.tabs( "refresh" );
            },
            beforeActivate: function( event, ui ) {
                PageLayout.checkPanelCKeditorsDirty($(ui.oldPanel));
            }
        });
        PageLayout.tab_element = easy_jquery_tabs;
        // Tabs are sortable
        easy_jquery_tabs.find( ".ui-tabs-nav" ).sortable({
            //axis: "x",
            update: function(event, ui) {
              var handler = ui.item.find(".easy-sortable-list-handle");
              var params = {data:{format:'json'}};
              // params.data[handler.data().name] = {reorder_to_position: ui.item.index() + 1}
              params.data['reorder_to_position'] = ui.item.index() + 1;

              $.ajax(handler.data().url, {data : params.data, type : 'PUT'});
              easy_jquery_tabs.tabs( "refresh" );
              PageLayout.change_link_current_tab($(".add-module-button"));

              var $edit_link = $(ui.item).find(".icon-edit");
              var href = $edit_link.attr("href");
              href = setAttrToUrl(href, 'is_preloaded', false)
              $edit_link.attr('href', href);
            }
        });

        easy_jquery_tabs.delegate( "a.icon-del", "ajax:success", function() {
            var panelId = $( this ).closest( "li" ).remove().attr( "aria-controls" );
            $( "#" + panelId ).remove();
            easy_jquery_tabs.tabs( "refresh" );
        });

        easy_jquery_tabs.on("change", "input, select, textarea", function(e){
            $(this).closest(".easy-page-module-form").attr('data-changed', true);
        });
        PageLayout.tabs_initialized = true
    },

    initSortable: function(options) {
        var o = $.extend({}, {
            tabIdPrefix: 'easy_jquery_tab',
            tabPos: false,
            tab_id: false,
            zoneName: false, // name of zone to become sortable
            updateUrl: false // url for ajax request when modules in zone are reordered
        }, options);

        if( o.tab_id === false || o.tabPos === false || !o.zoneName || !o.updateUrl) return;
        var tabId = o.tabIdPrefix + '-' + o.tab_id;

        $("#tab"+o.tabPos+"-list-" + o.zoneName).sortable({
            connectWith: '#' + tabId +" .easy-page-zone",
            handle: '.handle',
            start: function(event, ui){
                var cked = $(ui.item).find(".cke");
                if(cked.length > 0) {
                    var ck = CKEDITOR.instances[cked.attr("id").replace(/^cke_/, '')];
                    current_ck_text = ck.getData();
                    current_ck_config = ck.config;
                    ck.destroy()
                }
            },
            stop: function(event, ui){
                var cked = $(ui.item).find("textarea");
                if(cked.length > 0) {
                    try	{
                        CKEDITOR.replace(cked[0], current_ck_config).setData(current_ck_text);
                    } catch(exception){}
                }
            },
            update: function() {
                var serialized = $(this).sortable("serialize", {
                    key: "list-" + o.zoneName + "[]",
                    expression: /module_(.*)/
                });
                $.post(o.updateUrl + "&" + serialized);
            }
        });
    },

    addModule: function(e) {
        if( typeof e !== typeof undefined) {
            e.preventDefault();
        }
        var was_active_panel_id = PageLayout.getActivePanelId();
        var url = PageLayout.url_with_current_tab_param($(this).attr("href")) + "&" + $("#block-form").serialize();
        $.post( url, function(data) {
            $('#'+was_active_panel_id).find(".easy-page-zone:first").prepend(data);
        });
    },

    removeModule: function(button) {
        button = $(button);
        $.post(button.attr('href'), function() {
            button.closest(".easy-page-module-box").fadeOut('fast', function() {
                $(this).remove()
                });
        });
    },

    submitModules: function() {
        var activePanelId = PageLayout.getActivePanelId()

        PageLayout.checkPanelCKeditorsDirty($('#'+activePanelId) );
        var frmSettings = $("#easy-page_modules-settings-form");
        $(".easy-page-module-form[data-changed=true]").each(function() {
            var $this = $(this);
            var moduleCallbackName = $this.attr('id').replace(/module_/, 'before_submit_module_inside_').replace(/_form/, '').replace(/-/g, '_');
            if(typeof(window[moduleCallbackName]) == 'function') window[moduleCallbackName]();
            $("input,select,textarea:not(.wiki-edit)", this).each(function() {
                var cloned = $(this).clone().hide().appendTo(frmSettings);
                cloned.val($(this).val());
            });
            $(".wiki-edit", this).each(function() {
                board_value = null;
                if (typeof CKEDITOR === 'undefined') {
                    board_value = $(this).val();
                }
                else {
                    board_value = CKEDITOR.instances[this.id].getData()
                }
                $("<input/>").attr("type", "hidden").attr("name", this.name).val(board_value).appendTo(frmSettings);
            });
        });
        frmSettings.submit();
    },

    addTab: function() {
        $("#easy_page_editable_tabs_container").load($(this).attr('href'));
        return false;
    },

    removeTab: function(button, tab) {
        $.post($(button).attr("href"), function(data) {
            $("#easy_page_editable_tabs_container").replaceWith(data);
        });
        return false;
    },

    editTab: function(button, tab) {
        $(button).closest('li').load($(button).attr('href'));
        return false;
    },

    // ----- HELPERS -----
    change_link_current_tab: function($element) {
        var url = PageLayout.url_with_current_tab_param($element.attr('href'));
        $element.attr('href', url);
    },
    url_with_current_tab_param: function(url) {
        var current_tab = PageLayout.tab_element.tabs('option', 'active') + 1;
        url = PageLayout.setAttrToUrl(url, 't', current_tab);
        $tab = PageLayout.getActiveTab();
        if( $tab != false ) {
            url = PageLayout.setAttrToUrl(url, 'tab_id', $tab.find('.easy_tab_id').data('tab-id'));
        }
        return url;
    },
    checkPanelCKeditorsDirty: function($panel) {
        if(typeof CKEDITOR === typeof undefined)
            return true;
        $panel.find("textarea").each(function(index){
            var instance = CKEDITOR.instances[$(this).attr('id')];
            if( typeof instance === typeof undefined )
                return true;
            if(instance.checkDirty())
                $(this).closest(".easy-page-module-form").attr('data-changed', true);
        });
    },
    setAttrToUrl: function(url, name, value) {
        var attr_regex = RegExp(name+"=[^\&]+");
        if(url.match(attr_regex)) {
            return url.replace(attr_regex, name+'='+value);
        }

        if(!url.match(/\?/)) {
            url += '?';
        } else if (!url.match(/\&$/)) {
            url += '&';
        }
        url += name+'='+value;
        return url;
    }

};
