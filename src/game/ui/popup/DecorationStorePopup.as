package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ToolTipType;
	import game.proxy.Connection;
	import game.scenes.clubhouse.clubhouse.Clubhouse;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.hud.HudPopBrowser;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	/**
	 * DecorationStorePopup is store popup for decorations
	 */
	public class DecorationStorePopup extends Popup
	{
		// constants
		private const NUM_ITEMS:Number = 5;						// number of items per preview group
		private const PREV_SPAN:Number = 680;					// horizontal span of preview group (5 x 136)
		
		private var clubhouse:Clubhouse;
		private var currCredits:Number = 0;

		//ui
		private var memberPanel:MovieClip;
		private var buyPanel:MovieClip;
		private var currentItem:Object;
		
		// buttons
		private var leftArrow:Entity;
		private var rightArrow:Entity;
		
		// panels
		private var currentTab:String = "";						// name of current tab category
		private var numPanels:int = 0;							// total number of panels per category
		private var numItems:int = 0;							// total number of decoration items per category
		private var panels:Vector.<Entity>;						// array of panel entities (each panel holds 5 previews)			
		private var previewButtons:Vector.<Entity>;				// array of panel preview buttons
		private var dots:Vector.<MovieClip>;					// array of dots to indicate page
		private var itemPos:int = 0;							// current item position based on scrolling
		private var isScrolling:Boolean = false;				// is scrolling flag
		
		// groups
		private var wall:Array;
		private var furn:Array;
		private var appl:Array;
		private var misc:Array;
		private var wpap:Array;
		
		public function DecorationStorePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		public override function init(container:DisplayObjectContainer=null):void 
		{
			this.groupPrefix 		= "ui/clubhouse/";
			this.screenAsset 		= "store.swf";
			this.id = GROUP_ID;
			
			darkenBackground = true;
			
			super.init(container);
			super.load();
		}
		
		// pass arrays of items that have prices
		public function passArrays(clubhouse:Clubhouse, wallA:Array, furnA:Array, applA:Array, miscA:Array, wpapA:Array):void
		{
			// remember clubhouse
			this.clubhouse = clubhouse;
			wall = wallA;
			furn = furnA;
			appl = applA;
			misc = miscA;
			wpap = wpapA;
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			// stop at first frame (wall)
			this.screen.gotoAndStop(1);
			
			// show credits
			currCredits = shellApi.profileManager.active.credits;
			this.screen.credits.text = String(currCredits);
			
			// buttons
			ButtonCreator.createButtonEntity( this.screen.wallButton, this, Command.create(doTab, "wall"), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.furnButton, this, Command.create(doTab, "furn"), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.applButton, this, Command.create(doTab, "appl"), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.miscButton, this, Command.create(doTab, "misc"), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.wpapButton, this, Command.create(doTab, "wpap"), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.closeButton, this, handleCloseClicked, null, null, ToolTipType.CLICK);
			
			// arrow buttons
			this.screen.leftArrow.visible = false;
			this.screen.rightArrow.visible = false;
			leftArrow = ButtonCreator.createButtonEntity( this.screen.leftArrow, this, Command.create(scroll, -1), null, null, ToolTipType.CLICK);
			rightArrow = ButtonCreator.createButtonEntity( this.screen.rightArrow, this, Command.create(scroll, 1), null, null, ToolTipType.CLICK);
			showButton(leftArrow, false);
			showButton(rightArrow, false);

			// center screen
			this.screen.x = this.shellApi.viewportWidth * 0.5 - this.screen.width * 0.5;
			this.screen.y = this.shellApi.viewportHeight * 0.5 - this.screen.height * 0.5;
			
			// panels
			buyPanel = this.screen.buy;
			buyPanel.x = -2000;
			memberPanel = this.screen.member;
			memberPanel.x = -2000;
			
			// panel buttons
			ButtonCreator.createButtonEntity( this.screen.buy.noButton, this, Command.create(closePanel, buyPanel), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.buy.yesButton, this, buyItem, null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.member.noButton, this, Command.create(closePanel, memberPanel), null, null, ToolTipType.CLICK);
			ButtonCreator.createButtonEntity( this.screen.member.yesButton, this, buyMembership, null, null, ToolTipType.CLICK);
			
			// if first time showing, then show wall decorations
			doTab(null, "wall");
		}
		
		// when click tab button
		private function doTab(btn:Entity, category:String):void
		{
			// if new tab
			if (category != currentTab)
			{
				closeAllPanels();
				
				// remember category
				currentTab = category;
				
				// go to tab frame
				this.screen.gotoAndStop(category);
				
				// reset item position
				itemPos = 0;
				
				// clear all (entities and dots);
				for each (var panel:Entity in panels)
				{
					this.removeEntity(panel);
				}
				for each (var button:Entity in previewButtons)
				{
					this.removeEntity(button);
				}
				for (var dot:int = this.screen.dots.numChildren - 1; dot != -1; dot--)
				{
					this.screen.dots.removeChildAt(dot);
				}
				panels = new Vector.<Entity>();
				previewButtons = new Vector.<Entity>();
				dots = new Vector.<MovieClip>();;
				
				// hide arrows until after panels are loaded
				leftArrow.get(Display).visible = false;
				rightArrow.get(Display).visible = false;
				
				// get array for type
				var tabItems:Array = this[category];
				
				// create copy of array (name and id)
				var allItems:Array = [];
				for each (var item:Object in tabItems)
				{
					var newItem:Object = {};
					newItem.item_id = item.item_id;
					newItem.item_name = item.item_name;
					newItem.item_price = item.item_price;
					newItem.item_mem_only = item.item_mem_only;
					allItems.push(newItem);
				}
				numItems = allItems.length;
				
				// if no items then return
				if (numItems == 0)
				{
					return;
				}
				// if items
				else
				{
					// load each group of preview panels
					// calculate number of needed panels
					numPanels = Math.ceil(numItems/NUM_ITEMS);
					// starting position
					var pos:int = 0;
					
					// for each panel
					for (var i:int = 0; i!= numPanels; i++)
					{
						// get subset of array items
						var items:Array = [];
						for (var j:int = 0; j!= NUM_ITEMS; j++)
						{
							// for as many items in array
							if (allItems.length != 0)
							{
								items.push(allItems.shift());
							}
						}
						// load panel with preview items
						shellApi.loadFile(shellApi.assetPrefix + "ui/clubhouse/storePreview.swf", Command.create(panelLoaded, i, pos, items));
						
						// load dot if more than one panel
						if (numPanels != 1)
						{
							shellApi.loadFile(shellApi.assetPrefix + "ui/clubhouse/dot.swf", dotLoaded, i, numPanels);
						}
						// increment position
						pos += PREV_SPAN;
						
						// add dot holder
						dots.push(null);
					}
					
					// adjust arrows based on item pos
					doneScroll(false);
				}
			}
		}
		
		// PANELS ============================================================
		
		// when panel is loaded
		private function panelLoaded(clip:MovieClip, index:int, pos:int, items:Array):void
		{
			// add clip to previews holder and position
			clip = this.screen.previews.addChild(clip);
			clip.x = pos;
			
			// for each preview
			for (var i:int = 0; i!= NUM_ITEMS; i++)
			{
				// if item, then load item preview
				if (i < items.length)
				{
					var item:Object = items[i];
					
					trace("load " + item.item_name);
					
					// make preview clip clickable
					var preview:MovieClip = clip["preview" + i];
					var btn:Entity = ButtonCreator.createButtonEntity( preview, this, Command.create(clickPreview, preview, item), null, null, ToolTipType.CLICK);
					btn.add(new Id(item.item_id));
					
					// set price and member flag
					preview.price.text = String(item.item_price);
					if (item.item_mem_only == "0")
					{
						preview.member.visible = false;
					}
					
					// add to array of preview buttons
					previewButtons.push(btn);
					
					// load preview with server fallback
					var path:String = shellApi.assetPrefix + "clubhouse/" + item.item_name + "_preview.png";
					super.shellApi.loadFile(path, gotPreview, preview);
				}
				// if no item then hide
				else
				{
					clip["preview" + i].visible = false;
				}
			}
			
			// create preview panel entity and add to panels array
			var panelEntity:Entity = EntityUtils.createSpatialEntity(this, clip);
			panelEntity.add(new Id("panel" + index));
			panels.push(panelEntity);
			
			// hide panel if not first panel
			if (pos != 0)
			{
				panelEntity.get(Spatial).y = 10000;
			}
		}
		
		// when click preview
		private function clickPreview(e:Entity, preview:MovieClip, data:Object):void
		{
			// remember item data
			currentItem = data;
			
			// get panel
			var panel:MovieClip;
			// if member item and not member
			if ((preview.member.visible) && (!clubhouse.isMember))
			{
				panel = memberPanel;
			}
			else
			{
				panel = buyPanel;
			}
			// position panel
			panel.x = this.screen.previews.x + preview.x;
			panel.y = this.screen.previews.y + preview.y;
		}
		
		// LOADED FUNCTIONS ==================================================
		
		// when dot loaded
		private function dotLoaded(clip:MovieClip, pos:int, total:int):void
		{
			// dot spacing
			var spacing:int = 20;
			// add to dots holder
			clip = MovieClip(this.screen.dots.addChild(clip));
			// position and scale
			clip.x = -((total - 1) * spacing) / 2 + pos * spacing
			clip.scaleX = clip.scaleY = 0.35;
			// set frame
			if (pos == 0)
			{
				clip.gotoAndStop(2);
			}
			else
			{
				clip.gotoAndStop(1);
			}
			// add to array
			dots[pos] = clip;
		}
		
		// when preview is loaded
		private function gotPreview(clip:Object, location:MovieClip):void
		{
			if (clip)
			{
				// add to holder
				location.holder.addChild(clip);
				// hide loading clip
				location.loading.visible = false;
			}
		}
		
		// SCROLLING ==================================================
		
		// scroll inventory elements
		private function scroll(btn:Entity, dir:int):void
		{
			closeAllPanels();
			
			// if scrolling and arrow visible
			if ((!isScrolling) && (btn.get(Display).visible))
			{
				isScrolling = true;
				var time:Number = 0.4;
				
				// clear dot
				if (numPanels != 1)
				{
					dots[Math.floor(itemPos/NUM_ITEMS)].gotoAndStop(1);
				}
				
				// update item position
				itemPos += (dir * NUM_ITEMS);
				
				// scroll each panel
				for each (var panel:Entity in panels)
				{
					TweenUtils.entityTo(panel, Spatial, time, {y:0, x:panel.get(Spatial).x - dir * PREV_SPAN});
				}
				
				// set delay
				SceneUtil.delay(this, time, doneScroll);
				
				// show all tooltips
				showPanels(true);
			}
		}
		
		// done scrolling
		private function doneScroll(updateDot:Boolean = true):void
		{
			isScrolling = false;
			
			// if more than 5 items
			if (numItems > NUM_ITEMS)
			{
				// if items at top position, then hide bottom arrow, else show
				showButton(leftArrow, (itemPos != 0));
				// if extra items, then hide top arrow, else show
				showButton(rightArrow, (itemPos < numItems - NUM_ITEMS));
			}
			// if less than 5, then hide arrows
			else
			{
				showButton(leftArrow, false);
				showButton(rightArrow, false);
			}
			
			// set dot
			var page:int = Math.floor(itemPos/NUM_ITEMS);
			if ((updateDot) && (numPanels != 1))
			{
				dots[page].gotoAndStop(2);
			}
			
			// hide all panel except for page
			showPanels(false, page);
		}
		
		// show/hide panels
		private function showPanels(state:Boolean, keepPanel:int = -1):void
		{
			for (var i:int = panels.length - 1; i!=-1; i--)
			{
				var panel:Entity = this.getEntityById("panel" + i);
				if (state)
				{
					panel.get(Spatial).y = 0;
				}
				// if hiding
				else
				{
					if (i == keepPanel)
					{
						panel.get(Spatial).y = 0;
					}
					else
					{
						panel.get(Spatial).y = 10000;
					}
				}
			}
		}
		
		// show/hide button
		private function showButton(btn:Entity, state:Boolean):void
		{
			// set visibility
			btn.get(Display).visible = state;
			
			// set sleep
			Sleep(btn.get(Sleep)).sleeping = !state;
			
			// enable/disable tooltip
			if (state)
			{
				btn.add(new ToolTipActive());
			}
			else
			{
				btn.remove(ToolTipActive);
			}
		}
		
		// close member or buy panel
		private function closePanel(btn:Entity, panel:MovieClip):void
		{
			panel.x = -2000;
		}
		
		// close member and buy panels
		private function closeAllPanels():void
		{
			memberPanel.x = -2000;
			buyPanel.x = -2000;
		}
		
		// buy item
		private function buyItem(btnEntity):void
		{
			trace("buy " + currentItem.item_id);
			buyPanel.x = -2000;
			
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.password_hash 	= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.item_id 		= currentItem.item_id;
			vars.hard_price     = currentItem.item_price;
			
			// get data
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/redeem_credits_priced.php", vars, URLRequestMethod.POST, Command.create(donePurchase, currentItem.item_name));
		}
		
		// when done purchasing
		private function donePurchase(event:Event, item_name:String):void
		{
			var vars:URLVariables = new URLVariables(event.currentTarget.data);
			if (vars.status == "true")
			{
				trace("purchase success: " + vars.credits);
				
				// tracking
				shellApi.track(clubhouse.TRACK_BUY_DECORATION, item_name, null, "Clubhouse");

				var newCredits:Number = Number(vars.credits)
				currCredits = newCredits;
				// update credits in profile (don't need to save because it's done on backend at purchase time)
				shellApi.profileManager.active.credits = newCredits;
				// update display
				this.screen.credits.text = String(newCredits);
				// add to clubhouse inventory (if already in inventory, then increment max)
				clubhouse.boughtDecoration(currentItem);
			}
			else
			{
				trace("Purchase error: " + vars.error);
				var message:String = "Error with purchase!";
				// show message
				switch(vars.error)
				{
					case "insufficient-credit":
						message = "You don't have enough credits to buy this.";
						break;
				}
				// insufficient-credit
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, message)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(clubhouse.overlayContainer);
			}
		}
		
		// buy membership
		private function buyMembership(btn:Entity):void
		{
			memberPanel.x = -2000;

			HudPopBrowser.buyMembership(shellApi);
		}
		
		public static const GROUP_ID:String = "decoration_store";
	}
}