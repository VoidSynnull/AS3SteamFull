package game.scenes.hub.bundleShop
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.entity.Dialog;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Zone;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Proud;
	import game.data.bundles.BundleData;
	import game.data.scene.characterDialog.DialogData;
	import game.managers.BundleManager;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.hub.HubEvents;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class BundleShop extends PlatformerGameScene
	{		
		private var allBundlesPurchased:Boolean = false;
		
		public function BundleShop()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/bundleShop/";
			super.init(container);
		}
		
		public override function destroy():void 
		{
			this.shellApi.eventTriggered.remove(this.eventTriggered);
			super.destroy();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// make sure BundlManager is available, necessary for BundleShop & Arcade
			if( !shellApi.getManager(BundleManager) )
			{
				shellApi.addManager(new BundleManager());
			}
			
			this.shellApi.eventTriggered.add(this.eventTriggered);

			var bundleClip:MovieClip = super.getAsset( "bundle_showcase.swf" );
			var bundleGroup:BundleShowcase = new BundleShowcase( super._hitContainer, bundleClip );
			bundleGroup.ready.addOnce( setupScene );
			this.addChildGroup( bundleGroup );
			
			//Adding a zone around the bundle area of the shop so that camera focuses on the bundles.
			//This is to combat different screen sizes preventing you from seeing the whole shop.
			this.setupShopBrowsing();
			
			//super.loaded();
		}
		
		private function setupShopBrowsing():void
		{
			var entity:Entity = this.getEntityById("shopZone");
			if(entity)
			{
				trace("Entity");
				var zone:Zone = entity.get(Zone);
				if(zone)
				{
					trace("Zone");
					zone.entered.add(this.startShopping);
					zone.exitted.add(this.stopShopping);
					
					this.shellApi.inputEntity.add(new ZoneCollider());
					this.shellApi.inputEntity.add(new Motion());
				}
				
			}
		}
		
		private function startShopping(zoneID:String, colliderID:String):void
		{
			if(colliderID == "input")
			{
				SceneUtil.setCameraPoint(this, 484, 0);
			}
		}
		
		private function stopShopping(zoneID:String, colliderID:String):void
		{
			if(colliderID == "input")
			{
				SceneUtil.setCameraTarget(this, this.player);
			}
		}
		
		private function setupScene( bundleShowcase:BundleShowcase ):void
		{
			_bundlesManager = shellApi.getManager(BundleManager) as BundleManager;
			bundleShowcase.onBundlePurchased.add( onBundlePurchased );	// listen for when a bundle is purchased
			
			var ownerClip:DisplayObjectContainer = EntityUtils.getDisplayObject( this.getEntityById("owner") );
			DisplayUtils.moveToOverUnder( ownerClip, EntityUtils.getDisplayObject( super.player ), false );
			DisplayUtils.moveToOverUnder( bundleShowcase.groupContainer, ownerClip, false );
				
			this.setupShopOwner();
			
			super.loaded();
			
			//Adding a zone around the bundle area of the shop so that camera focuses on the bundles.
			//This is to combat different screen sizes preventing you from seeing the whole shop.
			this.setupShopBrowsing();
		}	
		
		private function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "proud_pose")
			{
				var owner:Entity = this.getEntityById("owner");
				CharUtils.setAnim(owner, Proud);
			}
		}
		
		private function setupShopOwner():void
		{
			var owner:Entity = this.getEntityById("owner");
			var dialog:Dialog = owner.get(Dialog);
			dialog.replaceKeyword("[PlayerName]", this.shellApi.profileManager.active.avatarName);
			
			if(!this.shellApi.checkEvent(HubEvents(this.events).TALKED_TO_SHOP_OWNER))
			{
				dialog.say("welcome");
			}
			else
			{
				if(this.checkIfAllPurchased())
				{
					dialog.sayById("social");
				}
				else
				{
					dialog.sayById("special");
					SceneUtil.addTimedEvent(this, new TimedEvent(30, 0, this.sayRecomendDialog));
				}
			}
		}
		
		private function onBundlePurchased( bundleData:BundleData ):void
		{
			var owner:Entity = this.getEntityById("owner");
			var dialog:Dialog = owner.get(Dialog);
			
			if(bundleData.free)
			{
				dialog.sayById("purchase");
			}
			else
			{
				dialog.sayById("free");
			}
			shellApi.track("BundlePurchased", bundleData.id);
			this.checkIfAllPurchased();
		}
		
		private function sayRecomendDialog():void
		{
			if(this.allBundlesPurchased) return;
			
			var owner:Entity = this.getEntityById("owner");
			var dialog:Dialog = owner.get(Dialog);
			var unownedBundleIds:Array = [];
			var ownedBundleIds:Array = this.shellApi.profileManager.active.bundlesOwned;
			
			var activeBundleId:String
			var index1:int = _bundlesManager.totalActiveBundles - 1;
			var index2:int;
			for(index1; index1 > -1; --index1)
			{
				var purchased:Boolean = false;
				activeBundleId = _bundlesManager.actveBundleDLCDatas[index1].id
				
				index2 = ownedBundleIds.length - 1;
				for(index2; index2 > -1; --index2)
				{
					if( activeBundleId == String(ownedBundleIds[index2]) )
					{
						purchased = true;
						break;
					}
				}
				
				if(!purchased)
				{
					unownedBundleIds.push(activeBundleId);
				}
			}
			
			if(unownedBundleIds.length > 0)
			{
				var string:String = DialogData(dialog.getDialog("recommend")).dialog;
				var bundleData:BundleData = _bundlesManager.getBundleData( unownedBundleIds[Utils.randInRange(0, unownedBundleIds.length - 1)] );
				if( bundleData )
				{
					string = string.replace("[BundleName]", bundleData.title);
					dialog._manualSay = string;
				}
			}
		}
		
		private function checkIfAllPurchased():Boolean
		{
			var ownedBundleIds:Array = this.shellApi.profileManager.active.bundlesOwned;

			var activeBundleId:String
			var index1:int = _bundlesManager.totalActiveBundles - 1;
			var index2:int;
			for(index1; index1 > -1; --index1)
			{
				var purchased:Boolean = false;
				activeBundleId = _bundlesManager.actveBundleDLCDatas[index1].id
				
				index2 = ownedBundleIds.length - 1
				for(index2; index2 > -1; --index2)
				{
					if( activeBundleId == String(ownedBundleIds[index2]) )
					{
						purchased = true;
						break;
					}
				}
				
				if(!purchased)
				{
					return false;
				}
			}
			
			this.allBundlesPurchased = true;
			this.shellApi.triggerEvent("bundles_all_purchased");
			return true;
		}
		
		private var _bundlesManager:BundleManager;
	}
}