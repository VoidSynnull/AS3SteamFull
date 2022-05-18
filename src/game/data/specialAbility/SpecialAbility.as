package game.data.specialAbility 
{
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.data.ParamData;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.LookData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.ActionsGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.actionChain.ActionChain;
	import game.util.ClassUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Base class for all Special Ability classes.
	 * @author Bard
	 */
	public class SpecialAbility extends Group
	{
		public function SpecialAbility()
		{
			super();
			super.id = "specialAbilityGroup";
			components = new Array();
		}
		
		/**
		 * Initialize the SpecialAbility, for override.
		 * addComponentsTo would be called here
		 */
		public function init( node:SpecialAbilityNode ):void
		{
			trace("init ability");
			// if entity doesn't have a look then suppress
			if (SkinUtils.getLook(node.entity, false) == null && !this.data.overrideSuppression)
			{
				trace("suppress " + data.id);
				suppressed = true;
			}
			else
			{
				trace("ability will init");
				// Appears that SpecialAbility groups don't actually get added to group manager and never injected.
				// remember entity and group and shellApi
				this.entity = node.entity;
				this.group = node.owning.group;
				this.group.addChildGroup(this);
				super.shellApi = node.owning.group.shellApi;
				this.theNode = node; // this is rarely needed but keep it
				
				trace("got here");
				// set properties from params
				setPropsFromParams();
				
				// if ad ability (starts with "limited"), then check for expired abilities
				// only do on web as mobile still uses ad zips
				if ((PlatformUtils.inBrowser) && (this.data.id) && (this.data.id.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) == 0))
				{
					checkExpired();
				}
			}
		}
		
		/**
		 * Set properties (starting with "_") from params list 
		 * @param params
		 */
		private function setPropsFromParams():void
		{
			// get params for this ability
			var params:Vector.<ParamData> = this.data.params.params;
			// get length of param array
			var len:int = params.length;
			// for each param
			for (var i:int = 0; i != len; i++)
			{
				// get param data
				var data:ParamData = params[i];
				// get value
				var value:String = String(data.value);
				// determine class property name
				var propertyID:String = "_" + data.id;
				trace("special ability property id: " + propertyID + " value: " + data.value);
				
				try
				{
					// check number value
					var numberVal:Number = Number(value);
					if (value.toLowerCase() == "true") // if true
						this[propertyID] = true;
					else if (value.toLowerCase() == "false") // if false
						this[propertyID] = false;
					else if (isNaN(numberVal)) // if string
					{
						// if contains comma, then assume array
						if (value.indexOf(",") != -1)
						{
							var arr:Array = value.split(",");
							// convert to numbers if array has numbers
							for (var j:int = arr.lenghth-1; j != -1; j--)
							{
								numberVal = Number(arr[j]);
								// if number, then swap
								if (!isNaN(numberVal))
									arr[j] = numberVal;
							}
							this[propertyID] = arr;
						}
							// if class
						else if (value.indexOf("game.") == 0)
						{
							this[propertyID] = ClassUtils.getClassByName(value);
						}
						else
						{
							this[propertyID] = value;
						}
					}
					else // if number
						this[propertyID] = numberVal;
				}
				catch (e:Error)
				{
					trace("special ability public property " + propertyID + " does not exist in class!");
				}
			}
		}
		
		/**
		 * Check for any expired ad abilities 
		 */
		private function checkExpired():void
		{
			// if legacy id found, then set id to legacy id
			if (_campaignId != 0)
				_id = _campaignId;
			
			// if no ID then error
			if (_id == 0)
			{
				trace("SpecialAbility: missing id param for " + this.data.id);
				suppressed = true;
			}
			// if not member
			else if (!super.shellApi.profileManager.active.isMember)
			{
				// convert to string
				var campaignID:String = String( _id );
				
				// get current inventory items
				var campaignItems:Vextor.<String> = super.shellApi.getCardSet(CardGroup.CUSTOM, true).cardIds;
				
				trace("SpecialAbility: active campaign items: " + campaignItems);
				
				// check against current campaigns
				// if not in list then remove ability and suppress
				if (campaignItems.indexOf(campaignID) == -1)
				{
					trace("SpecialAbility: remove " + this.data.id);
					super.shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, this.data.id);
					suppressed = true;
				}
			}
		}
		
		/**
		 * Activate the ability, for override
		 */
		public function activate( node:SpecialAbilityNode ):void
		{
		}
		
		/**
		 * Set SpecialAbilityData's isActive variable.
		 * @param	isActive
		 */
		protected function setActive( isActive:Boolean = false):void
		{
			if ( data )
				data.isActive = isActive;
		}
		
		/**
		 * Update node, for override
		 * @param node
		 * @param time
		 */
		public function update(node:SpecialAbilityNode, time:Number):void
		{
		}
		
		public function getLook():LookData
		{
			// to be overriden
			return null;
		}
		
		public function setLook(look:LookData):void
		{
			// to be overriden
		}
		
		/**
		 * 
		 * @param id - automatically adds the end prefix
		 * @param dictionary - dictionary of replacement entities. The key names should equal the xml string inside the [brackets]
		 * @param callback - the action chain is completed
		 * 
		 */		
		protected function actionCall(id:String = SpecialAbilityData.AFTER_ACTIONS_ID, dictionary:Dictionary = null, callback:Function = null):Boolean
		{
			// create dictionary if null
			if (dictionary == null)
			{
				var dict:Dictionary = new Dictionary();
				dict["entity"] = entity;
			}
			// don't add id if null
			if (data.id)
				id += "_" + data.id;
			
			var actionsGroup:ActionsGroup = this.data.actionsGroup;
			
			if(actionsGroup)
			{
				var actionChain:ActionChain = actionsGroup.getActionChain(id, dictionary);
				if(actionChain)
				{
					// need to pass node to action chain so that some actions can know which entity is being affected
					actionChain.execute(callback, theNode);	
					return true;
				}			
			}
			
			trace("Special Ability:: Could not find action chain specified as " + id);
			return false;
		}
		
		// FILE AND COMPONENT MANAGEMENT //////////////////////////////////////////////////////////////
		
		/**
		 * Add components if they aren't already added, for override
		 */
		protected function addComponentsTo( entity:Entity ):void
		{
		}
		
		/**
		 * Cache sound 
		 * @param url
		 */
		protected function cacheSound(url:String):void
		{
			var useServerFallback:Boolean = AppConfig.loadMissingPartsFromServer && PlatformUtils.isMobileOS;
			var soundManager:SoundManager = super.shellApi.getManager(SoundManager) as SoundManager;
			soundManager.cache(url, useServerFallback);
		}
		
		/**
		 * Load data file from url (not used) 
		 * @param url
		 * @param callback
		 */
		protected function loadData(url:String, callback:Function = null):void
		{
			if(AppConfig.loadMissingPartsFromServer && PlatformUtils.isMobileOS)
				super.shellApi.loadFile(super.shellApi.dataPrefix + url, callback);
			else
				super.shellApi.loadFile(super.shellApi.dataPrefix + url, callback);
		}
		
		/**
		 * Load asset 
		 * @param url
		 * @param callback
		 * @param args
		 */
		protected function loadAsset(url:String, callback:Function = null, ... args):void
		{
			var funct:Function = super.shellApi.loadFile;
			
			switch (args.length)
			{
				case 0:
					funct(super.shellApi.assetPrefix + url, callback);
					break;
				case 1:
					funct(super.shellApi.assetPrefix + url, callback, args[0]);
					break;
				case 2:
					funct(super.shellApi.assetPrefix + url, callback, args[0], args[1]);
					break;
				case 3:
					funct(super.shellApi.assetPrefix + url, callback, args[0], args[1], args[2]);
					break;
			}
		}
		
		/**
		 * Load array of assets 
		 * @param urls
		 * @param callback
		 * @param args
		 */
		protected function loadAssets(sourceUrls:Array, callback:Function = null, ... args):void
		{
			// make copy of urls
			var urls:Array = sourceUrls.slice();
			
			// add asset prefix to urls
			for (var i:int = urls.length-1; i != -1; i--)
			{
				urls[i] = super.shellApi.assetPrefix + urls[i];
			}
			
			var funct:Function = super.shellApi.loadFiles;
			
			switch (args.length)
			{
				case 0:
					funct(urls, callback);
					break;
				case 1:
					funct(urls, callback, args[0]);
					break;
				case 2:
					funct(urls, callback, args[0], args[1]);
					break;
				case 3:
					funct(urls, callback, args[0], args[1], args[2]);
					break;
			}
		}
		
		/**
		 * Load array of assets and pass array to callback 
		 * @param urls
		 * @param callback
		 * @param args
		 */
		protected function loadAssetsReturn(sourceUrls:Array, callback:Function = null, ... args):void
		{
			// make copy of urls
			var urls:Array = sourceUrls.slice();
			
			// add asset prefix to urls
			for (var i:int = urls.length-1; i != -1; i--)
			{
				urls[i] = super.shellApi.assetPrefix + urls[i];
			}
			
			var funct:Function = super.shellApi.loadFilesReturn;
			
			switch (args.length)
			{
				case 0:
					funct(urls, callback);
					break;
				case 1:
					funct(urls, callback, args[0]);
					break;
				case 2:
					funct(urls, callback, args[0], args[1]);
					break;
				case 3:
					funct(urls, callback, args[0], args[1], args[2]);
					break;
			}
		}
		
		// CLEANUP AND DISPOSAL /////////////////////////////////////////////
		
		/**
		 * Deactivate the ability, for override
		 */
		public function deactivate( node:SpecialAbilityNode ):void
		{
		}
		
		/**
		 * Called by SpecialAbilityControlSystem, can be overridden if necessary.
		 * @param	entity
		 */
		public function removeSpecial( node:SpecialAbilityNode ):void
		{
			if(data.actionsGroup)
			{
				this.data.actionsGroup.revertAllChains();
			}
			
			deactivate( node );
			removeComponents( node.entity );
		}
		
		/**
		 * Remove any components 
		 * @param entity
		 */
		protected function removeComponents( entity:Entity ):void
		{
			if (components != null)
			{
				// remove components if they are no longer needed.
				var component:Component;
				var componentClass:Class;
				
				for (var n:Number = 0; n < components.length; n++)
				{
					componentClass = components[n];
					component = entity.get(componentClass);
					
					if (component != null)
					{
						if (component.nodesAddedTo <= 1)
						{
							entity.remove(componentClass);
						}
					}
				}
			}
		}
		
		public function makeContentClickable():void
		{
			specialClicked = new Signal(SpecialAbilityData);
			var interaction:Interaction = InteractionCreator.addToEntity(data.entity, [InteractionCreator.CLICK, InteractionCreator.OVER, InteractionCreator.OUT]);
			interaction.click.add(clickedContent);
			
			if(!PlatformUtils.isMobileOS)
			{
				interaction.over.add(hoverContent);
				interaction.out.add(outContent);
			}
		}
		
		private function clickedContent(entity:Entity):void
		{
			specialClicked.dispatch(data);
		}
		
		private function hoverContent(entity:Entity):void
		{
			var clip:MovieClip = entity.get(Display).displayObject as MovieClip;
			clip.filters = [new GlowFilter(0xFFFFFF, 1, 10, 10, 2, 1)];
		}
		
		private function outContent(entity:Entity):void
		{
			var clip:MovieClip = entity.get(Display).displayObject as MovieClip;
			clip.filters = [];
		}
		
		public var _id:Number = 0; // from params - card number
		public var _campaignId:Number = 0; // from params - legacy card number
		public var _useSpecialActionBtn:Boolean = false; // add support for space bar trigger and action button for pop follower
		public var data:SpecialAbilityData;
		
		public var suppressed:Boolean = false;
		protected var components:Array;
		public var entity:Entity;
		protected var group:Group;
		protected var theNode:SpecialAbilityNode;
		
		public var specialClassLoaded:Signal;
		public var specialClicked:Signal;
	}
}