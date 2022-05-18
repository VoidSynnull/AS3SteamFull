package game.scene.template
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Scene;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.scene.template.ui.CardGroup;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class VendingMachineGroup extends DisplayGroup
	{
		public function VendingMachineGroup(container:DisplayObjectContainer=null)
		{
			super(container);
			this.id = "VendingMachineGroup";
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{			
		}
		
		override public function destroy():void
		{			
			super.groupContainer = null;
			super.destroy();
		}
		
		/**
		 * setup scene for vending machine
		 * @param scene
		 * @param hitContainer
		 * @param aXML	xml data object for vending machine
		 */
		public function setupScene(scene:Scene, hitContainer, aXML:XML):void
		{
			_scene = scene;
			
			// this group should inherit properties of the scene.
			this.groupPrefix = scene.groupPrefix;
			this.container = scene.container;
			this.groupContainer = hitContainer;
			
			var vMachine:MovieClip = hitContainer["vendingMachine"];
			// vending machine needs "art" clip to be converted to bitmap
			var vArt:MovieClip = vMachine["art"];
			if (vArt != null)
			{
				var layerBitmapData:BitmapData = new BitmapData(vArt.width, vArt.height, true, 0x000000);	
				layerBitmapData.draw(vArt);
				//vMachine.addChild(new MovieClip());	
				var vBitmap:Bitmap = new Bitmap(layerBitmapData, PixelSnapping.ALWAYS);
				vMachine.addChildAt(vBitmap, 0);
				vMachine.removeChild(vArt);
			}
			
			// process xml
			var vButtonNodes:XMLList = aXML.children();
			var vButtonXML:XML;
			var vID:String;
			var vWeek:String;
			for (var i:uint = 0; i < vButtonNodes.length(); i++)
			{
				vButtonXML = vButtonNodes[i];
				var vNodeName:String = String(vButtonXML.name());
				switch(vNodeName)
				{
					case "week":
						vWeek = String(vButtonXML.valueOf());
						break;
					case "campaign":
						_campaignName = String(vButtonXML.valueOf());
						_scene.shellApi.track("Impression", null, null, _campaignName);
						break;
					case "button":
						vID = String(vButtonXML.attribute("id"));
						// find button in clip
						// clips needs an dimmed overlay named "dim" and a text field named "tText"
						// text is unescaped so you can use %0D for a line return
						var vButton:MovieClip = vMachine[vID];
						if (vButton != null)
						{
							var vButtonSubNodes:XMLList = vButtonXML.children();
							var vButtonSubXML:XML;
							for (var j:uint = 0; j < vButtonSubNodes.length(); j++)
							{	
								vButtonSubXML = vButtonSubNodes[j];
								var vName:String = String(vButtonSubXML.name());
								var vValue:String = String(vButtonSubXML.valueOf());
								switch(vName)
								{
									case "name":
										// name of card
										vButton.cardname = vValue;
										break;
									case "card":
										// card id that get awarded
										vButton.card = vValue;
										break;
									case "member":
										// members only card flag
										vButton.member = (vValue == "true");
										break;
									case "active":
										// if active then hide dim and attach click interaction
										if (vValue.indexOf(vWeek) != -1)
										{
											vButton.dim.visible = false;
											vButton.tText.text = "";
											
											var vBtnEntity:Entity = new Entity();
											var vOverlay:MovieClip = new MovieClip();
											vOverlay.graphics.beginFill(0xFF0000, 0); // choosing the colour for the fill, here it is red
											vOverlay.graphics.drawRect(0, 0, vButton.width, vButton.height); // (x spacing, y spacing, width, height)
											vOverlay.graphics.endFill(); // not always needed but I like to put it in to end the fill
											var vSceneBtn:MovieClip = MovieClip(hitContainer.addChild(vOverlay));
											vSceneBtn.x = vButton.x + vMachine.x;
											vSceneBtn.y = vButton.y + vMachine.y;
											vSceneBtn.src = vButton;
											
											// apply any text and set to black text
											vButton.tText.text = unescape(String(vButtonSubXML.attribute("text")));
											vButton.tText.textColor = 0x000000;
											
											// add to display
											var vDisplay:Display = new Display(vSceneBtn, hitContainer);
											vBtnEntity.add(vDisplay);
											var vSpatial:Spatial = new Spatial(vSceneBtn.x, vSceneBtn.y);
											vBtnEntity.add(vSpatial);
											
											var interaction:Interaction = InteractionCreator.addToEntity(vBtnEntity, [InteractionCreator.CLICK]);
											vBtnEntity.add(interaction);
											interaction.click.add(fnHandleClicked);
											super.addEntity(vBtnEntity);
											
											// add tooltip
											var tooltipEntity:Entity = ToolTipCreator.create(ToolTipType.CLICK, vSceneBtn.x, vSceneBtn.y);
											EntityUtils.addParentChild(tooltipEntity, vBtnEntity);
											super.addEntity(tooltipEntity);
										}
										break;
									case "expired":
									case "coming":
										if (vValue.indexOf(vWeek) != -1)
										{
											vButton.tText.text = unescape(String(vButtonSubXML.attribute("text")));
										}
										break;
								}
							}
						}
						else
						{
							trace("VendingMachineGroup error: can't find button with name " + vID);
						}
						break;
				}
			}
		}
		
		private function fnHandleClicked(clickedEntity:Entity):void
		{
			trace("VendingMachineGroup :: click");
			// get source button
			var vSourceBtn:MovieClip = clickedEntity.get(Display).displayObject.src;
			_scene.shellApi.track("Clicked", vSourceBtn.cardname, null, _campaignName);
			
			var sceneUIGroup:SceneUIGroup = _scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;

			// check if member
			var vMember:String = vSourceBtn.member;
			var vAward:Boolean = false;
			// if member card
			if ((vMember != null) && (vMember == "true"))
			{
				// check member status and award
				if (_scene.shellApi.profileManager.active.isMember)
					vAward = true;
				else
					// if browser then go to membership tour
					if (PlatformUtils.inBrowser)
						sceneUIGroup.askForConfirmation(SceneUIGroup.VH_MEMBER_MESSAGE);	// FIX :: Having a Virus Hunter specific message here is problematic. - Bard
					else
						vAward = true;
			}
			else
			{
				// if not member card, then award
				vAward = true;
			}
			// if awarding
			if (vAward)
			{
				// if card not yet awarded
				if (!_scene.shellApi.checkHasItem(vSourceBtn.card, "store"))
				{
					_scene.shellApi.track("ObjectCollected", vSourceBtn.cardname, null, _campaignName);			
					_scene.shellApi.getItem(vSourceBtn.card, CardGroup.STORE, true);	

					// add a 2 second delay
					_timer = getTimer() + 2000;
				}
				// if have card and current time is greater than timer
				else if (getTimer() > _timer)
				{
					sceneUIGroup.askForConfirmation(SceneUIGroup.HAVE_ITEM_MESSAGE);
				}
			}
		}
		
		private var _scene:Scene;
		private var _campaignName:String;
		private var _timer:uint = 0;
	}
}