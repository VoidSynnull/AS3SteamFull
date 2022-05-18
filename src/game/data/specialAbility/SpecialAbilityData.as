package game.data.specialAbility
{
	import flash.display.DisplayObject;
	
	import ash.core.Entity;
	
	import game.components.specialAbility.SpecialAbilityControl;
	import game.data.ParamData;
	import game.data.ParamList;
	import game.data.tracking.TrackingData;
	import game.scene.template.ActionsGroup;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;

	/**
	 * ...
	 * @author Bard
	 */
	public class SpecialAbilityData
	{
		public function SpecialAbilityData( specialClass:Class = null, id:String = "",  ...args )
		{
			this.specialClass = specialClass;
			this.id = ( DataUtils.validString( id ) ) ? id : String(specialClass);

			params = new ParamList();
			params.addArray( args );
		}

		/**  Maintains reference to 'owning' component */
		public var control:SpecialAbilityControl;

		public var specialClass:Class;				// SpecialAbility class
		public var specialAbility:SpecialAbility;	// instantiated SpecialAbility
		
		public var actionsGroup:ActionsGroup;

		public var id:String;						// Unique id for ever special ability, Must Have. If not specified will use Class name

		public var params:ParamList;				// list of parameters used to define variables within a SpecialAbility class		
		public var state:String;					// used to hold state that can be saved during serialization
		public var triggerable:Boolean = true;		// determines if trigger can activate the SpecialAbility
		public var forceTracking:Boolean = true;	// forces ad tracking on first press - doesn't wait
		public var isActive:Boolean = false;		// flag to store active state, managed within SpecialAbility
		public var _invalidate:Boolean;				// set to true when activate is set or remove() is called
		public var entity:Entity;					// holds the entity if there is one
		public var useActionBtn:Boolean = false;	// flag denoting if special ability requires a button on screen for usage (currently used for mobile implementation)
		private var _activate:Boolean = false;
		public var stageW: Number = 2400;
		public var stageH: Number = 1000;
		public var saveToProfile:Boolean = false;
		public var overrideSuppression:Boolean = false;
		
		public var fullyLoaded:Signal = new Signal(SpecialAbilityData);
		
		public static const BEFORE_ACTIONS_ID:String = "before_actions";
		public static const AFTER_ACTIONS_ID:String = "after_actions";
		public static const NOW_ACTIONS_ID:String = "now_actions";
		public static const CLICK_ACTIONS_ID:String = "click_actions";

		// Tracking
		public var numTriggers:int = 0;
		public var timeSinceTrigger:Number = 0;
		public var trackData:TrackingData;
		public var trackPending:Boolean = false;

		private var _validIslands:Array;	// array of valid islands, if none are specified ability can be used on all islands
		private var abilityType:String;					// type of the SpecialAbility, if not specified uses SpecialAbility class. Used to compare and check if we should remove similar specials
		public function get type():String
		{
			if(abilityType) return abilityType;
			
			return id;
		}
		
		public function set type(newType:String):void
		{
			abilityType = newType;
		}

		public function addValidIsland(island:String):void
		{
			if(!_validIslands)
				_validIslands = new Array();

			_validIslands.push(island);
		}

		public function get activate():Boolean	{ return _activate; }
		public function set activate( bool:Boolean ):void
		{
			_activate = bool;
			_invalidate = true;
			control._invalidate = true;
		}

		private var _removeFlag:Boolean;
		public function get removeFlag():Boolean	{ return _removeFlag; }
		public function set removeFlag(bool:Boolean):void	{_removeFlag = bool; }
		public function remove():void
		{
			if ( !_removeFlag )
			{
				activate = false;
				_removeFlag = true;
				control._invalidate = true;
			}
		}

		// Should not be needed if we only save the special ability id and user params
		/*public function convertToXML():void
		{
			xmlData = new XML('<specialAbility id="' + id + '"/>');
			var qualifiedName:String = getQualifiedClassName(specialClass).toString();
			xmlData.className = qualifiedName.replace("::", ".");

			if(params)
			{
				var parameters:XML = new XML("<parameters/>");
				for each(var param:ParamData in params.params)
				{
					var child:XML;
					if(param.id)
						child = new XML('<param id="' + param.id +'"></param>');
					else
						child = new XML('<param/>');

					child.appendChild(param.value);
					parameters.appendChild(child);
				}
				xmlData.appendChild(parameters);
			}

			xmlData.useButton = useActionBtn.toString();
			xmlData.triggerable = triggerable.toString();
			xmlData.cardPreview = cardPreview.toString();

			if(_validIslands)
			{
				var islands:XML = new XML("<validIslands/>");
				var string:String = "";
				for(var i:int = 0; i < _validIslands.length; i++)
				{
					if(i != 0)
						string += ", ";
					string += _validIslands[i];
				}
				islands.appendChild(string);
				xmlData.appendChild(islands);
			}

			trace("SpecialAbilityData : convertToXML : xml is: " + xmlData);
		}*/

		public function parse(xml:XML):void
		{
			//trace("SpecialAbilityData xml: " + xml);
			this.id = DataUtils.getString( xml.attribute("id") );

			// default class name
			var className:String;
			if( xml.hasOwnProperty("className") )
				className = DataUtils.getString( xml.className );
			else
				className = "game.data.specialAbility.SpecialAbility";
			try
			{
				this.specialClass = ClassUtils.getClassByName( className );
				trace("SpecialAbilityData : parse : special ability class is: " + className);
			}
			catch(error:Error)
			{
				trace("Error :: SpecialAbilityData : parse : unable to find class: " + DataUtils.getString( className ));
			}
			
			// get save flag
			if(xml.hasOwnProperty("save"))
			{
				saveToProfile = DataUtils.getBoolean(xml.save);
			}
			
			// set special ability type //////////////////////////////////////////////////////////////
			
			// get basic class name
			var arr:Array = className.split(".");
			var shortName:String = arr[arr.length-1];
			
			// first, attempt to get type from SpecialAbilityTypes based on short class name
			if (this.specialClass)
			{
				var types:SpecialAbilityTypes = new SpecialAbilityTypes();
				this.abilityType = types.getType(shortName);
				types = null;
			}
			//trace("SpecialAbilityData: Type: " +  this.abilityType);
			
			// if type set in xml then use that instead (overrides class type)
			if( xml.hasOwnProperty("type") )
			{
				this.abilityType = DataUtils.getString( xml.type );
			}
			
			// If  type still hasn't been set yet, set it to short className
			if(this.abilityType == null)
			{
				this.abilityType = shortName;
			}
			trace("SpecialAbilityData: Type: " +  this.abilityType);
			
			//////////////////////////////////////////////////////////////
			
			if( xml.hasOwnProperty("parameters") )
			{
				var xParams:XMLList = xml.parameters.param;
				var param:ParamData;
				for (var i:int = 0; i < xParams.length(); i++)
				{
					param = new ParamData( xParams[i] );
					// NOTE :: Want tracking to be dealt with separately, unfortunately has already been placed within paramaters in many cases of ads
					// TODO :: Not keen on having tracking parameters sense via a string, as order is arbitrary, better to make use tags and ids throughout - bard
					if( param.id == "tracking" )
					{
						var trackingParams:Array = String(param.value).split(",");
						if( trackingParams.length > 0 )
						{
							this.trackData = new TrackingData();
							trackData.campaign = trackingParams[0];
							if( trackingParams.length > 1 )
							{
								trackData.choice = trackingParams[1];
								if( trackingParams.length > 2 )
								{
									trackData.subChoice = trackingParams[2];
								}
							}
						}
					}
					else
					{
						this.params.push( new ParamData( xParams[i] ) );
					}
				}
			}

			if( xml.hasOwnProperty("tracking") )
			{
				this.trackData = new TrackingData( xml.tracking );
			}

			if ( xml.hasOwnProperty("triggerable") )
			{
				this.triggerable = DataUtils.getBoolean( xml.triggerable );
			}

			if ( xml.hasOwnProperty("useButton") )
			{
				this.useActionBtn = DataUtils.getBoolean( xml.useButton );
			}

			if ( xml.hasOwnProperty("validIslands") )
			{
				_validIslands = DataUtils.getArray( xml.validIslands );
			}
			
			if ( xml.hasOwnProperty("forceTracking") )
			{
				this.forceTracking = DataUtils.getBoolean( xml.forceTracking );
			}
			
			if(xml.hasOwnProperty("actions"))
			{
				this.actionsGroup = new ActionsGroup(this.id);
				this.actionsGroup.addActionDatas(XML(xml.actions), this.id);
			}
			
			if(xml.hasOwnProperty("overrideSuppression"))
			{
				this.overrideSuppression = DataUtils.getBoolean(xml.overrideSuppression);
			}
			if(xml.hasOwnProperty("sfPauseTimer"))
			{
				this.sfPauseTimer = DataUtils.getNumber(xml.sfPauseTimer);
			}
			if(xml.hasOwnProperty("disableBroadcast"))
			{
				this.disableBroadcast = DataUtils.getBoolean(xml.disableBroadcast);
			}
		}

		private function createTracking():void
		{
			// ideally this is actually an XML, but in case of ads they are just using a String separated by commas
		}

		public function getInitParam( id:String ):String
		{
			return params.byId( id );
		}

		public function clone():SpecialAbilityData
		{
			var newAbility:SpecialAbilityData = new SpecialAbilityData(this.specialClass, this.abilityType);
			newAbility.params = this.params;
			newAbility.triggerable = this.triggerable;
			newAbility.isActive = false;

			return newAbility;
		}

		public function isValidIsland( currentIsland:String ):Boolean
		{
			if( _validIslands != null )
			{
				if( _validIslands.indexOf( currentIsland ) == -1 )
				{
					return false;
				}
			}
			return true;
		}
		public var sfPauseTimer:Number = 1;
		public var disableBroadcast:Boolean = true;
		////////////////////////////////////////////////////////////////////////
		///////////////////////////// ABILITY TYPES ////////////////////////////
		////////////////////////////////////////////////////////////////////////

		public static const ANIMATION:String = "animation";
		public static const PARTICLES:String = "particles";
	}

}
