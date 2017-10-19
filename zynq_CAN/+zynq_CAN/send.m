classdef send < zynq_CAN.base
     %send CAN Send socket
    %   Send messages to the network
    
    properties (Nontunable)
        % CANID 
        
        % The message ID to send
        % The ID is an 11-bit message ID
        CANID = 0;
    end
    
    properties (Hidden, Access = protected)
    end
    
    methods (Access = protected)
        function setupImpl(obj, data) %#ok<INUSD>
            openSocket(obj, 0);
        end
        
        function status = stepImpl(obj,data)
            status = coder.nullcopy(int32(0));
            if coder.target('Rtw')
                status = coder.ceval('sendCANData', obj.socket,...
                    uint32(obj.CANID),uint8(numel(data)),coder.rref(data));
            end
        end
        
        function icon = getIconImpl(obj) %#ok<MANU>
            icon = sprintf('CAN Send');
        end
        
    end
    
    %% External Dependency Methods
    methods (Static)
        function bName = getDescriptiveName(~)
            % getDescriptiveName get the name of the block
            % Internal function for Simulink Block generation
            bName = 'CAN Send';
        end
    end
    
    %% Propagation Methods
    methods (Hidden, Access = protected)
        
         %% Inputs validation
        function validateInputsImpl(~,data)
            if ~coder.target('Rtw')
                validateattributes(data, {'uint8'},{}, 1);
                if numel(data) > 8
                    error('Frame size must be 8 or less');
                end
            end
        end
        
        %% Initializers / Value Getters
        function N = getNumOutputsImpl(obj)
            % Specify number of System Outputs
            N = 1;
        end
        
        function [status] = getOutputSizeImpl(obj)
            status = 1;
        end
        
        function [status]= isOutputFixedSizeImpl(~)
            status = true;
        end
        
        function [status] = getOutputDataTypeImpl(~)
            status = 'int32';
        end
        
        function [status] =  getOutputNamesImpl(~)
            status = 'Status';
        end
        
        function [status] = isOutputComplexImpl(~)
            status = false;
        end
        
        
        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            N = 1;
        end
        
        
        function data = getInputNamesImpl(obj)
            data = 'Data';
        end
    end
end

