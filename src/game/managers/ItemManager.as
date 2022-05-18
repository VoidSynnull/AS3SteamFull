package game.managers
{
	/**
	 * A class to track items in a users inventory.  This class should not be used directly but accessed through ShellApi.
	 */
	
	import com.poptropica.AppConfig;
	
	import flash.utils.Dictionary;
	
	import engine.Manager;
	
	import game.data.TrackingEvents;
	import game.data.game.GameEvent;
	import game.data.ui.card.CardSet;
	import game.managers.interfaces.IItemManager;
	import game.proxy.DataStoreRequest;
	import game.scene.template.ItemGroup;
	import game.scene.template.ui.CardGroup;
	import game.util.DataUtils;
	import game.util.Utils;
	
	public class ItemManager extends Manager implements IItemManager
	{
		private var _storeItems:Dictionary = new Dictionary();
		
		public function ItemManager()
		{
			_cardSets = new Vector.<CardSet>();
			init()
		}
		
		/**
		 * FOR OVERRIDE 
		 * Initialize standard sets herr
		 */
		protected function init():void
		{
			// Example
			//addSet( CardGroup.CUSTOM );
			//addSet( CardGroup.STORE );
		}
		
		///////////////////////////////////////// SCENE METHODS  /////////////////////////////////////////
		
		/**
		 * Get an item.
		 * @param   item : The id of the item, can be an int or String.
		 * @param   [type] : The card type to add the item to.  Defaults to the current island.
		 * @param	showCard : optionally show the item's card
		 */
		public function getItem(item:*, type:String = null, showCard:Boolean = false, showCompleteCallback:Function = null):Boolean
		{
			// if card type not specified, determine type based on item
			if ( !DataUtils.validString(type) ) { type = determineType( item ); } 

			if (!checkHas(item, type)) 					// check that item is not already owned 
			{	
				if( checkValidItem( item, type ) )		// check that item is valid for specified type
				{
					add( String(item), type ) 			// Add item to ItemManager.

					// trigger events associated with item
					shellApi.gameEventManager.trigger(GameEvent.GET_ITEM + item, type, false);
					shellApi.gameEventManager.trigger(GameEvent.GOT_ITEM + item, type, true);
					shellApi.gameEventManager.trigger(GameEvent.HAS_ITEM + item, type, true);
					shellApi.track(GameEvent.GOT_ITEM + item);
					
					// notify ProfileManager that a new card has been received
					shellApi.profileManager.inventoryType = type;
					shellApi.profileManager.active.newInventoryCard = true;	// NOTE :: This must be set after setting inventroy type
					
					shellApi.track(TrackingEvents.GOT_ITEM, item);	// track item ( additional tracking is necessary for campaign cards, triggers in _____ 

					if (shellApi.needToStoreOnServer())		// attempt save item to server
					{
						shellApi.siteProxy.store(DataStoreRequest.itemGainedStorageRequest(item, type));
					}
					
					// Manages showing card via ItemGroup, may want to move this out at a later date. - Bard
					if(showCard)
					{
						showItem( String(item), type, showCompleteCallback );
					}
					return true;
				}
			}
			return false;
		}	
		
		public function showItem( itemId:String, type:String, transitionCompleteHandler:Function = null ):void
		{
			var sceneManager:SceneManager = shellApi.sceneManager;
			var itemGroup:ItemGroup = sceneManager.currentScene.getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			if( !itemGroup )
			{
				itemGroup = sceneManager.currentScene.addChildGroup( new ItemGroup() ) as ItemGroup;
				itemGroup.setupScene(sceneManager.currentScene);
			}

			if ( type == CardGroup.STORE || type == CardGroup.PETS )	
			{
				itemGroup.showItem( ItemGroup.ITEM_PREFIX + itemId, type, null, transitionCompleteHandler );
			}
			else
			{
				itemGroup.showItem(itemId, type, null, transitionCompleteHandler );
			}
		}
		
		///////////////////////////////////////// ITEM SETUP /////////////////////////////////////////
		
		/**
		 * Add an item
		 */
		public function add( item:String, setId:String, restore:Boolean = false ):Boolean
		{
			var cardSet:CardSet = getSet( setId );
			if( cardSet == null )
			{
				cardSet = new CardSet(setId);
				_cardSets.push( cardSet );
			}
			
			if( cardSet.add( item ) )
			{
				saveItemsToProfile(setId);
				return(true);
			}
			
			return(false);
		}
		
		public function remove(item:String, setId:String):Boolean
		{
			var cardSet:CardSet = getSet( setId );
			if( cardSet != null )
			{
				if( cardSet.remove(item) )
				{
					saveItemsToProfile(setId);
					return(true);
				}
			}
			
			return(false);
		}
		
		/**
		 * Check to see if the player has an item in their inventory.
		 * Note if they've gotten the item and then had it removed (ex : given it to an npc)
		 * this will evaluate to 'false' since the item isn't
		 * in the users inventory. To check if the player has EVER had an item, use <code>checkItemEvent(item)</code>.
		 * @param item	The item to check for.
		 * @param setId	The setId to check the item for. Defaults to the current island, valid values are island names, "store", &amp; "custom/limited"
		 */
		public function checkHas(item:String, setId:String):Boolean
		{
			var cardSet:CardSet = getSet( setId );
			if( cardSet != null )
			{
				return cardSet.has(item);
			}
			else
			{
				return(false);
			}
		}
		
		/**
		 * Check if item is valid for specified type.
		 */
		public function checkValidItem(item:String, setId:String):Boolean
		{
			// currently only checking validity of island items for current island
			if( shellApi.island == setId )
			{
				var numItems:int = validCurrentItems.length;
				for (var i:int = 0; i < numItems; i++) 
				{
					if( item == validCurrentItems[i] )
					{
						return true;
					}
				}
			}
			else
			{
				return true;
			}
			
			return false;
		}
		
		/**
		 * FOR OVERRIDE
		 * Determine type based on item id.
		 */
		public function determineType(item:String):String
		{
			return shellApi.island;
		}
		
		/**
		 * Returns CardSet if it exists, otherwise makes a new CardSet with given setId and returns that.
		 * @param setId
		 * @param filterExpired
		 * @return 
		 */
		public function getMakeSet( setId:String, filterExpired:Boolean = false ):CardSet
		{
			if (setId == null)
			{
				setId = shellApi.island;
			}
			
			var cardSet:CardSet = getSet( setId, filterExpired );
			if( cardSet == null )
			{
				cardSet = new CardSet(setId);
				_cardSets.push( cardSet );
			}
			
			return( cardSet );
		}
		
		public function getSets():Vector.<CardSet>
		{
			return _cardSets.concat();
		}
		
		/**
		 * If no set is specified removes all sets
		 */
		public function reset( setId:String = null, save:Boolean = true ):void
		{
			if( setId != null )
			{
				var cardSet:CardSet = getSet( setId );
				if( cardSet != null )
				{
					cardSet.reset();
					if(save)
					{
						shellApi.profileManager.active.items[cardSet.id] = new Array();
					}
				}
			}
			else
			{
				//_cardSets.length = 0;
				for (var i:int = 0; i < _cardSets.length; i++) 
				{
					_cardSets[i].reset();
					if(save)
					{
						shellApi.profileManager.active.items[_cardSets[i].id] = new Array();
					}
					_cardSets[i] = null;
				}
				_cardSets = new Vector.<CardSet>();
				
				if(save)
				{
					shellApi.profileManager.save();
				}
				// NOTE :: should we save store and custom/limited? 
			}
		}
		

		/**
		 * Convert item ids back into CardSets.
		 * If set is not specified restores all sets with given Dictionary.
		 * @param itemSets - Dictionary, using key of setId, of Arrays containing item ids
		 * @param setId - id of the set of items ( example store, custom, carrot )
		 */
		public function restoreSets( itemSets:Dictionary, setId:String = null ):void
		{
			if( setId != null)
			{
				restoreSet( setId, itemSets[setId] );
			}
			else
			{
				var itemSet:String;	
				for( itemSet in itemSets)
				{
					restoreSet( itemSet, itemSets[itemSet] );
				}
			}
		}
		
		/**
		 * Convert item ids back into CardSet.
		 * @param setId - id of the set of items ( example store, custom, carrot )
		 * @param items - Arrays containing item ids
		 */
		public function restoreSet( setId:String, items:Array ):void
		{
			if( DataUtils.validString(setId) )
			{
				var total:int = items.length;
				var index:uint = 0;
				var itemsId:*;
				
				for(index = 0 ; index < total; index++)
				{
					itemsId = items[index];
					if( checkValidItem( itemsId, setId ) )
					{
						add(itemsId, setId, true);
					}
				}
			}
		}
		
		private function saveItemsToProfile( setId:String ):void
		{
			var cardSet:CardSet = getSet(setId);
			if( cardSet )
			{
				shellApi.profileManager.active.items[setId] = Utils.convertVectorToArray( getSet(setId).cardIds );
				shellApi.saveGame();
			}
			else
			{
				if(shellApi.profileManager.active.items[setId] == null)
				{
					shellApi.profileManager.active.items[setId] = new Array();
				}
			}
		}
		
		////////////////////////////////////////////////////////////
		////////////////////////// HELPERs /////////////////////////
		////////////////////////////////////////////////////////////
		
		protected function addSet( id:String ):CardSet
		{
			var currentSet:CardSet = getSet( id )
			if( !currentSet )
			{
				currentSet = new CardSet( id )
				_cardSets.push( currentSet );
			}
			return currentSet;
		}
		
		/**
		 * Get stored CardSet by id
		 * @param id - id of card set attempting to retrieve
		 * @param filterExpired - flag determining if card set should be filter for possiblye experation
		 * @return 
		 * 
		 */
		protected function getSet( id:String, filterExpired:Boolean = false):CardSet
		{
			var cardSet:CardSet;
			for (var i:int = 0; i < _cardSets.length; i++)
			{
				cardSet = _cardSets[i];
				if ( cardSet.id == id )
				{
					return cardSet;
				}
			}
			trace("ItemManager :: getSet : no CardSet found for id: " + id);
			return null;
		}
		
		public function getStoreItemInfo(id:String,category:String):Object
		{
			var catDict:Array = _storeItems[category];
			
			for(var i:Number=0;i<catDict.length;i++)
			{
				var storeItem:Object = catDict[i];
				if(storeItem.id == id)
					return storeItem;
			}
			return null;
		}
		
		public function getStoreItemType(id:String):String
		{
			// check all categories to find match to id
			var list:Array = [COSTUME,FOLLOWER,MISC,POWER,PRANK,PET,PET_FACIAL,PET_HAT,PET_EYES,PET_BODY,MEMBER_GIFT];
			for each (var category:String in list)
			{
				// in the case of mobile, there won't be any categories retrieved
				if ((_storeItems[category + "ID"] != null) && (_storeItems[category + "ID"].indexOf(id) != -1))
					return category;
			}
			return null;
		}

		public function isMembersCard(id:String):Boolean
		{
			if (_storeItems[MEMBERS_ONLY] == null)
				return false;
			return ((_storeItems[MEMBERS_ONLY] as Array).indexOf(id) != -1);
		}

		public static const POWER:String = "2003";
		public static const PRANK:String = "2004";
		public static const FOLLOWER:String = "2011";
		public static const MISC:String = "2012";
		public static const COSTUME:String = "2013";
		public static const PET:String = "2014";
		public static const MEMBER_GIFT:String = "2015";
		public static const PET_FACIAL:String = "2016";
		public static const PET_HAT:String = "2017";
		public static const PET_EYES:String = "2018";
		public static const PET_BODY:String = "2019";
		public static const MEMBERS_ONLY:String = "member";

		static private var _suppressedStoreItems:Vector.<int> = new <int>[
			/*
			// won't be converted
			3021, 3023, 3024, 3025, 3052, 3057, 3081, 3082, 3090, 3100, 3109, 3113, 3132, 3133, 3134,
			3146, 3147, 3166, 3167, 3189, 3190, 3210, 3211, 3212, 3213, 3214, 3223, 3224, 3228, 3229, 3230, 3231, 3232,
			3237, 3238, 3239, 3240, 3241, 3244, 3289, 3293, 3294, 3295, 3318, 
			
			// remaining to be converted
			3065, 3093, 3094, 3142, 3143, 3144, 3157, 3159, 3161, 3162, 3174, 3176, 3177, 3182, 3183,
			3205, 3207, 3209, 3218, 3219, 3220, 3221, 3222, 3225, 3226, 3227, 3253, 3257, 3258, 3259,
			3260, 3262, 3279, 3280, 3285, 3286, 3291, 3292, 3296, 3297, 3298, 3299, 3305, 3311, 3316, 3317, 3319, 3321, 3327, 3337,
			
			// won't be converted
			3328, 3334, 3336, 3346, 3366, 3391, 3392, 3440
			*/
			3021, 3023, 3024, 3025, 3052, 3057, 3058, 3060, 3066, 3081, 3082, 3090, 3091, 3100, 3109, 3113, 3132, 3133, 
			3134, 3146, 3147, 3158, 3166, 3167, 3168, 3169, 3170, 3171, 3172, 3173, 3174, 3175, 3176, 3177, 3182, 3186, 
			3187, 3188, 3189, 3190, 3191, 3192, 3193, 3198, 3199, 3200, 3201, 3205, 3207, 3208, 3209, 3210, 3211, 3212, 
			3213, 3214, 3215, 3216, 3219, 3220, 3221, 3222, 3223, 3224, 3226, 3227, 3228, 3229, 3230, 3231, 3232, 3234, 
			3237, 3238, 3239, 3240, 
			3241, 3244, 3248, 3249, 3253, 3255, 3256, 3259, 3260, 3261, 3267, 3279, 3281, 3282, 3287, 3288, 3289, 3290, 
			3293, 3294, 3295, 3296, 3297, 3298, 3302, 3303, 3305, 3308, 3309, 3312, 3314, 3315, 3318, 3319, 3322, 3323, 
			3325, 3328, 3329, 3333, 3334, 3336, 3337, 3338, 3339, 3340, 3342, 3346, 3347, 3349, 3357, 3361, 3362, 3363, 
			3364, 3365, 3366, 3369, 3370, 3371, 3372, 3375, 3376, 3377, 3378, 3379, 3380, 3382, 3383, 3391, 3392, 3394, 
			3395, 3396, 3397, 3399, 3400, 3401, 3403, 3404, 3405, 3406, 3407, 3408, 3409, 3410, 3411, 3412, 3413, 3414, 
			3415, 3416, 3417, 3418, 3419, 3420, 3421, 3422, 3423, 3424, 3425, 3426, 3427, 3428, 3429, 3430, 3431, 3432, 
			3433, 3434, 3435, 3436, 3437, 3438, 3440, 3444, 3451, 3452, 3453, 3454, 3455, 3456, 3457, 3458, 3459, 3460, 
			3461, 3462, 3463, 3464, 3465, 3468, 3469, 3470, 3471, 3472, 3473, 3478, 3479, 3480, 3481, 3482, 3483, 3484, 
			3485, 3486, 3487, 3488, 3496, 3497, 3498, 3499, 3500, 3501, 3502, 3503, 3504, 3505, 3506, 3507, 3508, 3509, 
			3510, 3511, 3512, 3513, 3514, 3515, 3516, 3523, 3525, 3526, 3527, 3528, 3531, 3532, 3533, 3534, 3535, 3536, 
			3537, 3538, 3539, 3540, 3541, 3542, 3543, 3544, 3545, 3546, 3548, 3549, 3550, 3552, 3553, 3554, 3557, 3558, 
			3559, 3569, 3576, 3598, 3600, 3602, 3603, 3605, 3606, 3607, 3608, 3610, 3611
		];
		
		static public function isStoreItemConverted(id:int):Boolean
		{
			if ((id > 3723) && (id < 5000)) {
				return false;
			}
			if (_suppressedStoreItems.indexOf(id) == -1)
			{
				return true;
			}
			return false;
		}

		private var _validCurrentItems:Vector.<String> = new Vector.<String>();
		public function get validCurrentItems():Vector.<String>				{ return _validCurrentItems; }
		public function set validCurrentItems( value:Vector.<String>):void	{ _validCurrentItems = value; }
		
		protected var _cardSets:Vector.<CardSet>;	// Dictionary of CardTypeSets
		public function get cardSets():Vector.<CardSet>	{ return _cardSets; }
		
		public var _cardGroupClass:Class = CardGroup;
		public function get cardGroupClass():Class				{ return _cardGroupClass; }
		public function set cardGroupClass( value:Class):void	{ _cardGroupClass = value; }
		
		public function get storeItems():Dictionary	 { return _storeItems; }
		public function set storeItems(value:Dictionary):void { _storeItems = value; }
	}
}